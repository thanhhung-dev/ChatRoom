import Foundation
@preconcurrency import MultipeerConnectivity

struct LocalDiscoveredUser: Equatable {
  let peerID: MCPeerID
  let userId: Int
  let username: String
  let displayName: String
  let lastSeenAt: Date

  static func == (lhs: LocalDiscoveredUser, rhs: LocalDiscoveredUser) -> Bool {
    lhs.userId == rhs.userId
  }
}

protocol LocalPeerDiscoveryServiceDelegate: AnyObject {
  func localPeerDiscoveryDidUpdateUsers(_ users: [LocalDiscoveredUser])
}

final class LocalPeerDiscoveryService: NSObject {
  static let shared = LocalPeerDiscoveryService()

  private let serviceType = "boxchat-peer"
  private var peerID: MCPeerID?
  private var advertiser: MCNearbyServiceAdvertiser?
  private var browser: MCNearbyServiceBrowser?
  private var discoveredByUserId: [Int: LocalDiscoveredUser] = [:]

  weak var delegate: LocalPeerDiscoveryServiceDelegate?

  private override init() {
    super.init()
  }

  func start(currentUser: UserResponse?) {
    guard let currentUser else { return }
    stop()

    let displayName = currentUser.displayName ?? currentUser.username
    let peer = MCPeerID(displayName: "\(currentUser.id)-\(currentUser.username)")
    let discoveryInfo: [String: String] = [
      "user_id": "\(currentUser.id)",
      "username": currentUser.username,
      "display_name": displayName,
    ]

    peerID = peer
    advertiser = MCNearbyServiceAdvertiser(
      peer: peer,
      discoveryInfo: discoveryInfo,
      serviceType: serviceType)
    browser = MCNearbyServiceBrowser(peer: peer, serviceType: serviceType)

    advertiser?.delegate = self
    browser?.delegate = self
    advertiser?.startAdvertisingPeer()
    browser?.startBrowsingForPeers()
    notify()
  }

  func stop() {
    advertiser?.stopAdvertisingPeer()
    browser?.stopBrowsingForPeers()
    advertiser = nil
    browser = nil
    discoveredByUserId.removeAll()
    notify()
  }

  private func notify() {
    let users = discoveredByUserId.values.sorted {
      $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
    }
    DispatchQueue.main.async { [weak self] in
      self?.delegate?.localPeerDiscoveryDidUpdateUsers(users)
    }
  }
}

extension LocalPeerDiscoveryService: MCNearbyServiceAdvertiserDelegate {
  func advertiser(
    _ advertiser: MCNearbyServiceAdvertiser,
    didReceiveInvitationFromPeer peerID: MCPeerID,
    withContext context: Data?,
    invitationHandler: @escaping (Bool, MCSession?) -> Void
  ) {
    invitationHandler(false, nil)
  }
}

extension LocalPeerDiscoveryService: MCNearbyServiceBrowserDelegate {
  func browser(
    _ browser: MCNearbyServiceBrowser,
    foundPeer peerID: MCPeerID,
    withDiscoveryInfo info: [String: String]?
  ) {
    guard let info,
      let rawId = info["user_id"],
      let userId = Int(rawId),
      let username = info["username"],
      userId != TokenManager.shared.currentUser?.id
    else { return }

    discoveredByUserId[userId] = LocalDiscoveredUser(
      peerID: peerID,
      userId: userId,
      username: username,
      displayName: info["display_name"] ?? username,
      lastSeenAt: Date()
    )
    notify()
  }

  func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
    discoveredByUserId = discoveredByUserId.filter { $0.value.peerID != peerID }
    notify()
  }
}
