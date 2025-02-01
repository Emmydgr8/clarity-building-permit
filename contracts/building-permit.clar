;; Define data structures
(define-map permits
    { permit-id: uint }
    {
        owner: principal,
        status: (string-ascii 20),
        property-address: (string-ascii 100), 
        permit-type: (string-ascii 50),
        issue-date: uint,
        expiry-date: uint,
        approved-by: (optional principal),
        fees-paid: uint,
        extension-count: uint
    }
)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-status (err u103))
(define-constant err-insufficient-fees (err u104))
(define-constant err-max-extensions (err u105))

;; Data vars
(define-data-var permit-nonce uint u0)
(define-data-var base-permit-fee uint u100)
(define-data-var extension-fee uint u50)
(define-data-var max-extensions uint u2)

;; Private functions
(define-private (is-admin (caller principal))
    (is-eq caller contract-owner)
)

;; Public functions
(define-public (submit-permit-application 
    (property-address (string-ascii 100))
    (permit-type (string-ascii 50))
    (expiry-date uint)
)
    (let
        (
            (permit-id (+ (var-get permit-nonce) u1))
        )
        (try! (map-insert permits
            { permit-id: permit-id }
            {
                owner: tx-sender,
                status: "PENDING",
                property-address: property-address,
                permit-type: permit-type,
                issue-date: block-height,
                expiry-date: expiry-date,
                approved-by: none,
                fees-paid: u0,
                extension-count: u0
            }
        ))
        (var-set permit-nonce permit-id)
        (ok permit-id)
    )
)

(define-public (pay-permit-fees (permit-id uint))
    (let
        (
            (permit (unwrap! (map-get? permits { permit-id: permit-id }) err-not-found))
            (fee (var-get base-permit-fee))
        )
        (if (is-eq (get owner permit) tx-sender)
            (begin
                (try! (stx-transfer? fee tx-sender contract-owner))
                (try! (map-set permits
                    { permit-id: permit-id }
                    (merge permit {
                        fees-paid: fee
                    })
                ))
                (ok true)
            )
            err-unauthorized
        )
    )
)

(define-public (extend-permit (permit-id uint) (new-expiry uint))
    (let
        (
            (permit (unwrap! (map-get? permits { permit-id: permit-id }) err-not-found))
            (current-extensions (get extension-count permit))
        )
        (if (> current-extensions (var-get max-extensions))
            err-max-extensions
            (if (is-eq (get owner permit) tx-sender)
                (begin
                    (try! (stx-transfer? (var-get extension-fee) tx-sender contract-owner))
                    (try! (map-set permits
                        { permit-id: permit-id }
                        (merge permit {
                            expiry-date: new-expiry,
                            extension-count: (+ current-extensions u1)
                        })
                    ))
                    (ok true)
                )
                err-unauthorized
            )
        )
    )
)

(define-public (approve-permit (permit-id uint))
    (let
        (
            (permit (unwrap! (map-get? permits { permit-id: permit-id }) err-not-found))
        )
        (if (and (is-admin tx-sender) (>= (get fees-paid permit) (var-get base-permit-fee)))
            (begin
                (try! (map-set permits
                    { permit-id: permit-id }
                    (merge permit {
                        status: "APPROVED",
                        approved-by: (some tx-sender)
                    })
                ))
                (ok true)
            )
            err-unauthorized
        )
    )
)

(define-public (reject-permit (permit-id uint))
    (let
        (
            (permit (unwrap! (map-get? permits { permit-id: permit-id }) err-not-found))
        )
        (if (is-admin tx-sender)
            (begin
                (try! (map-set permits
                    { permit-id: permit-id }
                    (merge permit {
                        status: "REJECTED",
                        approved-by: (some tx-sender)
                    })
                ))
                (ok true)
            )
            err-unauthorized
        )
    )
)

(define-read-only (get-permit (permit-id uint))
    (ok (map-get? permits { permit-id: permit-id }))
)

(define-read-only (get-permit-status (permit-id uint))
    (match (map-get? permits { permit-id: permit-id })
        permit (ok (get status permit))
        err-not-found
    )
)
