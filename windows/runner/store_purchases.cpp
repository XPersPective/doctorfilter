#include "store_purchases.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>

#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Services.Store.h>

#include <shobjidl_core.h>

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;
using flutter::MethodCall;
using flutter::MethodResult;
using winrt::Windows::Services::Store::StoreContext;
using winrt::Windows::Services::Store::StorePurchaseStatus;

constexpr char kChannelName[] = "com.crazypenguin.doctorfilter/store";

using Result = std::shared_ptr<MethodResult<EncodableValue>>;

std::wstring Widen(const std::string& value) {
  return std::wstring(value.begin(), value.end());
}

std::string Narrow(const winrt::hstring& value) {
  return winrt::to_string(value);
}

std::string ProductIdArgument(const MethodCall<EncodableValue>& call) {
  if (const auto* arguments = std::get_if<EncodableMap>(call.arguments())) {
    const auto entry = arguments->find(EncodableValue("productId"));
    if (entry != arguments->end()) {
      if (const auto* id = std::get_if<std::string>(&entry->second)) return *id;
    }
  }
  return {};
}

// A desktop app has no CoreWindow, so the Store's purchase dialog has nothing to
// parent itself to unless it is handed the HWND. Without this the purchase call
// fails outright rather than showing a dialog.
StoreContext ContextFor(HWND window) {
  StoreContext context = StoreContext::GetDefault();
  if (auto initialize = context.try_as<::IInitializeWithWindow>()) {
    initialize->Initialize(window);
  }
  return context;
}

// Every call resumes on the thread it started on before answering Dart.
// Flutter's Windows embedder only accepts replies on the platform thread, and
// Store operations complete on a thread pool.

winrt::fire_and_forget LoadOffer(HWND window, std::wstring product_id,
                                 Result result) {
  winrt::apartment_context platform_thread;
  bool failed = false;
  try {
    const auto products = co_await ContextFor(window).GetAssociatedStoreProductsAsync(
        {L"Durable"});
    co_await platform_thread;

    if (products.ExtendedError() != winrt::hresult{}) {
      result->Error("store_unavailable", "The Store could not be reached.");
      co_return;
    }

    for (const auto& pair : products.Products()) {
      const auto product = pair.Value();
      if (product.InAppOfferToken() != product_id) continue;

      result->Success(EncodableValue(EncodableMap{
          {EncodableValue("id"), EncodableValue(Narrow(product.InAppOfferToken()))},
          {EncodableValue("title"), EncodableValue(Narrow(product.Title()))},
          {EncodableValue("description"),
           EncodableValue(Narrow(product.Description()))},
          {EncodableValue("price"),
           EncodableValue(Narrow(product.Price().FormattedPrice()))},
      }));
      co_return;
    }

    result->Error("product_not_found",
                  "No add-on with that Product ID is associated with this app.");
  } catch (const winrt::hresult_error&) {
    // Running unpackaged — a debug build — lands here. There is no Store
    // identity to ask about, and saying so is better than a hang.
    failed = true;
  }
  if (failed) {
    // co_await is not allowed inside a catch block, so the thread hop happens
    // here. Resuming on a thread we are already on is a no-op.
    co_await platform_thread;
    result->Error("store_unavailable", "The Store is not available here.");
  }
}

winrt::fire_and_forget IsOwned(HWND window, std::wstring product_id,
                               Result result) {
  winrt::apartment_context platform_thread;
  bool failed = false;
  try {
    const auto license = co_await ContextFor(window).GetAppLicenseAsync();
    co_await platform_thread;

    bool owned = false;
    for (const auto& pair : license.AddOnLicenses()) {
      const auto add_on = pair.Value();
      if (add_on.InAppOfferToken() == product_id && add_on.IsActive()) {
        owned = true;
        break;
      }
    }
    result->Success(EncodableValue(owned));
  } catch (const winrt::hresult_error&) {
    failed = true;
  }
  if (failed) {
    co_await platform_thread;
    result->Error("store_unavailable", "The Store is not available here.");
  }
}

winrt::fire_and_forget Buy(HWND window, std::wstring product_id, Result result) {
  winrt::apartment_context platform_thread;
  bool failed = false;
  try {
    StoreContext context = ContextFor(window);
    const auto products =
        co_await context.GetAssociatedStoreProductsAsync({L"Durable"});

    for (const auto& pair : products.Products()) {
      const auto product = pair.Value();
      if (product.InAppOfferToken() != product_id) continue;

      const auto purchase = co_await product.RequestPurchaseAsync();
      co_await platform_thread;

      // Mapped to the same outcome names the Dart side already uses for Play
      // and the App Store, so the paywall does not need a Windows branch.
      std::string outcome;
      switch (purchase.Status()) {
        case StorePurchaseStatus::Succeeded:
          outcome = "purchased";
          break;
        case StorePurchaseStatus::AlreadyPurchased:
          outcome = "restored";
          break;
        case StorePurchaseStatus::NotPurchased:
          outcome = "cancelled";
          break;
        default:
          outcome = "unavailable";
          break;
      }
      result->Success(EncodableValue(outcome));
      co_return;
    }

    co_await platform_thread;
    result->Success(EncodableValue("unavailable"));
  } catch (const winrt::hresult_error&) {
    failed = true;
  }
  if (failed) {
    co_await platform_thread;
    result->Success(EncodableValue("unavailable"));
  }
}

}  // namespace

void RegisterStorePurchases(flutter::BinaryMessenger* messenger, HWND window) {
  // Kept alive by the handler's capture for as long as the engine runs.
  auto channel = std::make_shared<flutter::MethodChannel<EncodableValue>>(
      messenger, kChannelName, &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [window, channel](const MethodCall<EncodableValue>& call,
                        std::unique_ptr<MethodResult<EncodableValue>> reply) {
        Result result(std::move(reply));
        const std::wstring product_id = Widen(ProductIdArgument(call));
        const std::string& method = call.method_name();

        if (product_id.empty() &&
            (method == "loadOffer" || method == "isOwned" || method == "buy")) {
          result->Error("bad_arguments", "productId is required");
          return;
        }

        if (method == "loadOffer") {
          LoadOffer(window, product_id, result);
        } else if (method == "isOwned") {
          IsOwned(window, product_id, result);
        } else if (method == "buy") {
          Buy(window, product_id, result);
        } else {
          result->NotImplemented();
        }
      });
}
