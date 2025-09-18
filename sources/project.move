module MyModule::FixedInterestLoans {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;

    /// Struct representing a fixed-interest loan.
    struct Loan has store, key {
        principal: u64,           // Original loan amount
        interest_rate: u64,       // Interest rate in basis points (e.g., 500 = 5%)
        duration: u64,            // Loan duration in seconds
        start_time: u64,          // When the loan was taken
        lender: address,          // Address of the lender
        is_repaid: bool,          // Whether the loan has been repaid
    }

    /// Function to create a fixed-interest loan offer.
    /// @param lender: The account offering the loan
    /// @param borrower: The address that will receive the loan
    /// @param principal: The loan amount
    /// @param interest_rate: Interest rate in basis points (500 = 5%)
    /// @param duration: Loan duration in seconds
    public fun create_loan(
        lender: &signer,
        borrower: address,
        principal: u64,
        interest_rate: u64,
        duration: u64
    ) {
        let loan = Loan {
            principal,
            interest_rate,
            duration,
            start_time: timestamp::now_seconds(),
            lender: signer::address_of(lender),
            is_repaid: false,
        };

        // Transfer loan amount to borrower
        let loan_coins = coin::withdraw<AptosCoin>(lender, principal);
        coin::deposit<AptosCoin>(borrower, loan_coins);

        // Store loan details under borrower's account
        move_to(lender, loan);
    }

    /// Function to repay the loan with interest.
    /// @param borrower: The account repaying the loan
    /// @param lender: The original lender's address
    public fun repay_loan(borrower: &signer, lender: address) acquires Loan {
        let loan = borrow_global_mut<Loan>(lender);
        assert!(!loan.is_repaid, 1); // Ensure loan hasn't been repaid already

        // Calculate total repayment amount (principal + interest)
        let interest = (loan.principal * loan.interest_rate) / 10000;
        let total_repayment = loan.principal + interest;

        // Transfer repayment to lender
        let repayment_coins = coin::withdraw<AptosCoin>(borrower, total_repayment);
        coin::deposit<AptosCoin>(loan.lender, repayment_coins);

        // Mark loan as repaid
        loan.is_repaid = true;
    }
}