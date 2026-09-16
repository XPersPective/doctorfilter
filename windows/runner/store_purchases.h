#ifndef RUNNER_STORE_PURCHASES_H_
#define RUNNER_STORE_PURCHASES_H_

#include <flutter/binary_messenger.h>
#include <windows.h>

// Microsoft Store purchases for the one thing the app sells.
//
// Uses the add-on's InAppOfferToken — the Product ID typed into Partner Center
// when the add-on is created — rather than the Store ID Microsoft assigns. That
// token is chosen by the developer, so it can be the same
// `doctorfilter_pro_lifetime` used on Google Play and the App Store, and the
// code does not depend on an identifier that only exists after registration.
void RegisterStorePurchases(flutter::BinaryMessenger* messenger, HWND window);

#endif  // RUNNER_STORE_PURCHASES_H_
