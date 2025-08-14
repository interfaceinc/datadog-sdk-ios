//
//  AppRestrictedModePublisher.swift
//
//
//  Created by Remi Santos on 10/06/2024.
//

import Foundation

public final class AppRestrictedMode {
  public static func setMode(enabled: Bool) {
    if enabled {
      NotificationCenter.default.post(name: AppRestrictedModePublisher.AppRestrictedNotification.enableRestrictedMode, object: nil)
    } else {
      NotificationCenter.default.post(name: AppRestrictedModePublisher.AppRestrictedNotification.disableRestrictedMode, object: nil)
    }
  }
}

internal final class AppRestrictedModePublisher: ContextValuePublisher {
  let initialValue = false

  private var receiver: ContextValueReceiver<Bool>?

  var current: Bool = false {
    didSet { receiver?(current) }
  }

  /// The default publisher queue.
  private static let defaultQueue = DispatchQueue(
    label: "com.datadoghq.app-restricted-mode-publisher",
    target: .global(qos: .utility)
  )

  /// The notification center where this publisher observes the notifications
  private let notificationCenter: NotificationCenter = .default

  enum AppRestrictedNotification {
    static let enableRestrictedMode = Notification.Name("enableAppRestrictedMode")
    static let disableRestrictedMode = Notification.Name("disableAppRestrictedMode")
  }

  func publish(to receiver: @escaping ContextValueReceiver<Bool>) {
    Self.defaultQueue.async { self.receiver = receiver }
    notificationCenter.addObserver(self, selector: #selector(enableRestrictedMode), name: AppRestrictedNotification.enableRestrictedMode, object: nil)
    notificationCenter.addObserver(self, selector: #selector(disableRestrictedMode), name: AppRestrictedNotification.disableRestrictedMode, object: nil)
  }

  @objc
  private func enableRestrictedMode() {
    self.receiver?(true)
  }

  @objc
  private func disableRestrictedMode() {
    self.receiver?(false)
  }

  func cancel() {
    notificationCenter.removeObserver(self, name: AppRestrictedNotification.enableRestrictedMode, object: nil)
    notificationCenter.removeObserver(self, name: AppRestrictedNotification.disableRestrictedMode, object: nil)
    Self.defaultQueue.async { self.receiver = nil }
  }
}

