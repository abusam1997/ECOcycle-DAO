;; ============================================================
;; EcoCycleDAO.clar
;; Decentralized Recycling Incentive & Funding DAO
;; Version: 2.0 (Refactored)
;; ============================================================

;; =========================
;; ERROR CONSTANTS
;; =========================
(define-constant ERR-NOT-AUTHORIZED (err u403))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-INVALID (err u400))
(define-constant ERR-INSUFFICIENT (err u402))
(define-constant ERR-ALREADY-VOTED (err u409))
(define-constant ERR-EXECUTED (err u410))
(define-constant ERR-NO-QUORUM (err u411))

;; =========================
;; CONFIGURATION
;; =========================
(define-data-var admin principal tx-sender)
(define-constant REWARD_RATE u10)
(define-constant QUORUM u1000)

;; Internal DAO treasury key
(define-constant DAO (as-contract tx-sender))

;; =========================
;; STORAGE
;; =========================

;; Token ledger
(define-map balances
  { user: principal }
  { amount: uint }
)

;; Staking
(define-map stakes
  { user: principal }
  { amount: uint }
)

;; Recycling submissions
(define-map submissions
  { id: uint }
  { user: principal, weight: uint, verified: bool }
)

(define-data-var submission-id uint u1)

;; Proposals
(define-map proposals
  { id: uint }
  {
    creator: principal,
    title: (string-ascii 60),
    description: (string-ascii 80),
    amount: uint,
    votes: uint,
    executed: bool
  }
)

(define-data-var proposal-id uint u1)

;; Voting tracker
(define-map votes
  { proposal: uint, voter: principal }
  { voted: bool }
)

;; =========================
;; READ FUNCTIONS
;; =========================

(define-read-only (balance-of (user principal))
  (default-to u0 (get amount (map-get? balances { user: user })))
)

(define-read-only (stake-of (user principal))
  (default-to u0 (get amount (map-get? stakes { user: user })))
)

(define-read-only (get-proposal (id uint))
  (map-get? proposals { id: id })
)

(define-read-only (get-submission (id uint))
  (map-get? submissions { id: id })
)

;; =========================
;; INTERNAL HELPERS
;; =========================

(define-private (credit (user principal) (amt uint))
  (let ((bal (balance-of user)))
    (map-set balances { user: user } { amount: (+ bal amt) })
  )
)

(define-private (debit (user principal) (amt uint))
  (let ((bal (balance-of user)))
    (if (< bal amt)
        ERR-INSUFFICIENT
        (begin
          (map-set balances { user: user } { amount: (- bal amt) })
          (ok true)
        )
    )
  )
)

;; =========================
;; TOKEN OPERATIONS
;; =========================

(define-public (mint (amount uint))
  (begin
    (asserts! (> amount u0) ERR-INVALID)
    (credit tx-sender amount)
    (print { event: "mint", user: tx-sender, amount: amount })
    (ok amount)
  )
)

(define-public (fund-dao (amount uint))
  (begin
    (asserts! (> amount u0) ERR-INVALID)
    (match (debit tx-sender amount)
      ok-result (begin
           (credit DAO amount)
           (print { event: "dao-funded", from: tx-sender, amount: amount })
           (ok amount)
         )
      err-result (err err-result)
    )
  )
)

;; =========================
;; RECYCLING LOGIC
;; =========================

(define-public (submit (weight uint))
  (let ((id (var-get submission-id)))
    (begin
      (asserts! (> weight u0) ERR-INVALID)

      (map-set submissions
        { id: id }
        { user: tx-sender, weight: weight, verified: false })

      (var-set submission-id (+ id u1))

      (print { event: "submitted", id: id, user: tx-sender })
      (ok id)
    )
  )
)

(define-public (verify (id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-AUTHORIZED)

    (let ((entry (map-get? submissions { id: id })))
      (asserts! (is-some entry) ERR-NOT-FOUND)

      (let ((s (unwrap-panic entry)))
        (if (get verified s)
            ERR-INVALID
            (begin
              (map-set submissions { id: id }
                { user: (get user s), weight: (get weight s), verified: true })

              (let ((reward (* (get weight s) REWARD_RATE)))
                (credit (get user s) reward)
                (print { event: "verified", id: id, reward: reward })
                (ok reward)
              )
            )
        )
      )
    )
  )
)

;; =========================
;; STAKING
;; =========================

(define-public (stake (amount uint))
  (begin
    (asserts! (> amount u0) ERR-INVALID)

    (match (debit tx-sender amount)
      ok-result (let ((cur (stake-of tx-sender)))
           (map-set stakes { user: tx-sender } { amount: (+ cur amount) })
           (ok true))
      err-result (err err-result)
    )
  )
)

(define-public (unstake (amount uint))
  (let ((cur (stake-of tx-sender)))
    (if (< cur amount)
        ERR-INSUFFICIENT
        (begin
          (map-set stakes { user: tx-sender } { amount: (- cur amount) })
          (credit tx-sender amount)
          (ok true)
        )
    )
  )
)

;; =========================
;; GOVERNANCE
;; =========================

(define-public (propose (title (string-ascii 60)) (desc (string-ascii 80)) (amount uint))
  (let ((id (var-get proposal-id)))
    (begin
      (asserts! (> amount u0) ERR-INVALID)

      (map-set proposals
        { id: id }
        {
          creator: tx-sender,
          title: title,
          description: desc,
          amount: amount,
          votes: u0,
          executed: false
        })

      (var-set proposal-id (+ id u1))

      (print { event: "proposal", id: id })
      (ok id)
    )
  )
)

(define-public (vote (id uint))
  (let (
        (prop (map-get? proposals { id: id }))
        (power (stake-of tx-sender))
       )
    (asserts! (is-some prop) ERR-NOT-FOUND)
    (asserts! (> power u0) ERR-INSUFFICIENT)

    (if (is-some (map-get? votes { proposal: id, voter: tx-sender }))
        ERR-ALREADY-VOTED
        (let ((p (unwrap-panic prop)))
          (begin
            (map-set votes { proposal: id, voter: tx-sender } { voted: true })

            (map-set proposals { id: id }
              {
                creator: (get creator p),
                title: (get title p),
                description: (get description p),
                amount: (get amount p),
                votes: (+ (get votes p) power),
                executed: (get executed p)
              })

            (ok power)
          )
        )
    )
  )
)

(define-public (execute (id uint))
  (let ((prop (map-get? proposals { id: id })))
    (asserts! (is-some prop) ERR-NOT-FOUND)

    (let ((p (unwrap-panic prop)))
      (if (get executed p)
          ERR-EXECUTED
          (if (< (get votes p) QUORUM)
              ERR-NO-QUORUM
              (let ((dao-bal (balance-of DAO)))
                (if (< dao-bal (get amount p))
                    ERR-INSUFFICIENT
                    (begin
                      (try! (debit DAO (get amount p)))
                      (credit (get creator p) (get amount p))

                      ;; FIXED BUG: update correct proposal ID
                      (map-set proposals { id: id }
                        {
                          creator: (get creator p),
                          title: (get title p),
                          description: (get description p),
                          amount: (get amount p),
                          votes: (get votes p),
                          executed: true
                        })

                      (print { event: "executed", id: id })
                      (ok true)
                    )
                )
              )
          )
      )
    )
  )
)

;; =========================
;; ADMIN
;; =========================

(define-public (set-admin (new principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-AUTHORIZED)
    (var-set admin new)
    (ok new)
  )
)
