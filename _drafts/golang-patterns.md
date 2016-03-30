
Empty struct 
============

If you just need a channel to work like a semaphore (no data), use the thing than means "no data": even less data than `nil`.

```go
shutdown := make(chan struct{})

shutdown <- struct{}{}
```

(Dave Cheney writes a lot more about fun with empty structs.)[http://dave.cheney.net/2014/03/25/the-empty-struct]

Roll your own "goroutine complete" notification
===============================================

Say you've got a long-running daemon-style subsystem `Subsystem`. It goes through the following phases:

- initializing
- done initialization
- ready!
- running ↺ until shutdown!
- shutting down
- done

So it starts up, signals that it's ready, loops servicing something until it receives a shutdown signal, then shuts down and returns.

A typical use case would be to spawn one of these for each new connection in a socket server. However, we want to do a graceful shutdown, to inform clients and tidy up. Furthermore, the supersystem wants to know that the subsystem is done.

In Go, my initial thinking went like this. (Assume comms is a simplified messaged-based, bi-directional socket.)

```go
func subsystem(comms chan interface{}, ready, shutdown, done chan struct{}) {
  //init
Loop: for {
    select {
    case msg := <-comms:
      //...
    case <-shutdown:
      break Loop
    }
  }
  comms <- "I must go now" 
  done <- struct{}{}
}

func supersystem(externalSignal chan struct{}) {
  comms := make(chan interface{})
  ready := make(chan struct{})
  shutdown := make(chan struct{})
  done := make(chan struct{})
  go subsystem(comms, ready, shutdown, done)

  <-externalSignal
  shutdown <- struct{}{}
  <-done
}
```

After some time, I found a simplification. I thought: "that `done` `chan` seems wrong somehow", and it is! We already have a perfectly good way of signalling completion: `return`, and that happens already; `done` is redundant.

The problem is that we're running `subsystem` as a goroutine, meaning we don't get a return value from it. Luckily this is easily fixed:

```go
func subsystem(comms chan interface{}, ready, shutdown chan struct{}{}) {
  //init
Loop: for {
    select {
    case msg := <-comms:
      //...
    case <-shutdown:
      break Loop
    }
  }
  comms <- "I must go now" 
}

func supersystem(externalSignal chan struct{}) {
  comms := make(chan interface{})
  ready := make(chan struct{})
  shutdown := make(chan struct{})
  done := make(chan struct{})
  go func() {
    subsystem(comms, ready, shutdown)
    done <- struct{}{}
  }

  <-externalSignal
  shutdown <- struct{}{}
  <-done
}
```

This keeps the responsibility of signaling completion close to its usage. When we had `done` in subsystem, its reason for existing wouldn't have been clear without tracing through its caller; it's a leaky encapsulation.

