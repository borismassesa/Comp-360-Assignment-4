# Comp-360-Assignment-4 -- Robotic Arm Ball Transfer

## Overview
This project demonstrates a robotic arm that picks up a ball, rotates, and drops it onto a ramp. The ball then rolls down pathways, eventually returning to the base of the robot arm. This scenario uses animations, physics interactions, and environment setup in Godot.

**Key Features:**
- Animated robotic arm that can detect and grab a ball.
- Ball release onto a ramp, allowing gravity to roll it down to the arm’s base.
- State machine controlling the arm’s workflow: IDLE, GRABBING, ROTATING, RELEASING, RESETTING.
- Integration of animations (“grab” and “letgo”) with physics-based ball movement.

## Setup & Run
1. Open `main.tscn` in Godot 4.x.
2. Press the Play button to start.
3. The arm will attempt to pick up the ball, rotate, and drop it onto the ramp. The ball will roll down the paths and return near the arm’s base.

## Breakdown of Tasks & Contributions

**Marwa,Boris,Karan: Environment & Camera Setup**
- Positioned `main.tscn` elements (arm, ball, ramp).
- Set up camera to view the entire action.
- Arranged lighting and environment for visibility.

**Boris,Karan,Marwa : Arm Animation & State Machine**
- Created state machine for the arm (`IDLE`, `GRABBING`, `ROTATING`, `RELEASING`, `RESETTING`).
- Imported “grab” and “letgo” animations.
- Implemented logic to synchronize grabbing with animation states.

**Karan,Marwa,Boris : Ball Physics & Ramp Design**
- Created `Ball` as a `RigidBody3D` with `CollisionShape3D`.
- Adjusted ball properties (freeze/unfreeze) and verified it rolls smoothly down the ramp.
- Ensured ramp has correct collision shapes for a smooth pathway.

**Boris & Marwa & Karan : Signal Integration & Debugging**
- Connected `GrabArea` signals (`body_entered`, `body_exited`) to arm logic.
- Debugged issues with ball detection, layering, and timing.
- Confirmed that the sequence completes and resets correctly.
