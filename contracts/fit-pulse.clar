;; FitPulse Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-invalid-input (err u101))
(define-constant err-challenge-ended (err u102))
(define-constant err-insufficient-balance (err u103))

;; Define token
(define-fungible-token fit-token)

;; Data structures
(define-map user-profiles
  principal
  {
    level: uint,
    total-workouts: uint,
    xp: uint,
    tokens-earned: uint
  }
)

(define-map workouts
  uint
  {
    user: principal,
    workout-type: (string-ascii 64),
    duration: uint,
    intensity: uint,
    timestamp: uint,
    tokens-rewarded: uint
  }
)

(define-map challenges
  uint
  {
    creator: principal,
    title: (string-ascii 64),
    start-time: uint,
    end-time: uint,
    reward: uint,
    participants: (list 50 principal)
  }
)

;; Variables
(define-data-var workout-counter uint u0)
(define-data-var challenge-counter uint u0)
(define-data-var tokens-per-minute uint u10)

;; Public functions
(define-public (record-workout (workout-type (string-ascii 64)) (duration uint) (intensity uint))
  (let
    (
      (workout-id (+ (var-get workout-counter) u1))
      (current-time (get-block-info? time (- block-height u1)))
      (token-reward (calculate-token-reward duration intensity))
    )
    (map-set workouts workout-id
      {
        user: tx-sender,
        workout-type: workout-type,
        duration: duration,
        intensity: intensity,
        timestamp: (default-to u0 current-time),
        tokens-rewarded: token-reward
      }
    )
    (var-set workout-counter workout-id)
    (calculate-and-award-xp tx-sender duration intensity)
    (mint-workout-tokens tx-sender token-reward)
    (ok workout-id)
  )
)

(define-public (create-challenge (title (string-ascii 64)) (duration uint) (reward uint))
  (let
    (
      (challenge-id (+ (var-get challenge-counter) u1))
      (start-time (get-block-info? time (- block-height u1)))
    )
    (map-set challenges challenge-id
      {
        creator: tx-sender,
        title: title,
        start-time: (default-to u0 start-time),
        end-time: (+ (default-to u0 start-time) duration),
        reward: reward,
        participants: (list)
      }
    )
    (var-set challenge-counter challenge-id)
    (ok challenge-id)
  )
)

;; Internal functions
(define-private (calculate-and-award-xp (user principal) (duration uint) (intensity uint))
  (let
    (
      (xp-earned (* duration intensity))
      (current-profile (default-to {level: u1, total-workouts: u0, xp: u0, tokens-earned: u0} 
        (map-get? user-profiles user)))
    )
    (map-set user-profiles user
      {
        level: (calculate-level (+ (get xp current-profile) xp-earned)),
        total-workouts: (+ (get total-workouts current-profile) u1),
        xp: (+ (get xp current-profile) xp-earned),
        tokens-earned: (+ (get tokens-earned current-profile) (calculate-token-reward duration intensity))
      }
    )
    (ok true)
  )
)

(define-private (calculate-token-reward (duration uint) (intensity uint))
  (* (* duration (var-get tokens-per-minute)) intensity)
)

(define-private (mint-workout-tokens (user principal) (amount uint))
  (ft-mint? fit-token amount user)
)

(define-private (calculate-level (xp uint))
  (+ u1 (/ xp u1000))
)

;; Read only functions
(define-read-only (get-user-profile (user principal))
  (ok (map-get? user-profiles user))
)

(define-read-only (get-workout (workout-id uint))
  (ok (map-get? workouts workout-id))
)

(define-read-only (get-challenge (challenge-id uint))
  (ok (map-get? challenges challenge-id))
)

(define-read-only (get-token-rate)
  (ok (var-get tokens-per-minute))
)
