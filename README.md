# WebRTC VideoChat

MiniVideoChat is a small demo iOS app that implements a simple **Caller ↔ Callee** video call:

- UI: **SwiftUI**
- Architecture: **MVVM + Coordinator(Stinsen)**
- Signaling: **Socket.IO**
- Video: **WebRTC**
- Async: **Swift Concurrency (async/await, AsyncStream)**

---

## Socket.IO setup

The signaling server runs locally (Node.js, `index.js`).

In `SocketIOService` you must set your **Mac’s local IP**:

```swift
#if targetEnvironment(simulator)
let url = URL(string: "http://localhost:3000")!        // Simulator → localhost
#else
let url = URL(string: "http://192.168.0.10:3000")!     // Device → Mac local IP
#endif
```
Replace 192.168.0.10 with your actual Mac IP address on the local network.

---

## Usage flow
1. Start signaling server
```bash
npm install
node index.js
```
2. Run the app on two clients
	*	Option A: Simulator + physical iPhone
	*	Option B: Two Simulators

4. Configure Caller
	1.	Enter a username and roomId.
	2.	Set the role switch to Caller.
	3.	Tap Connect to join the room.
  
5. Configure Callee
	1.	On the second client, enter a different username and the same roomId.
	2.	Set the role switch to **Callee**.
	3.	Tap Connect to join the same room.

6. Start the call
	1.	When both peers are connected to the same room with opposite roles (Caller / Callee), the Caller sees the Start Call button enabled.
	2.	The Caller taps Start Call.
	3.	The Video Chat screen opens, and WebRTC establishes the connection (offer/answer + ICE candidates exchange).

  
