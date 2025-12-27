module risein::swap {
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::signer;
    use aptos_framework::account;
    use std::error;

    struct TokenA {}
    struct TokenB {}

    const E_NOT_ADMIN: u64 = 1;
    const E_INSUFFICIENT_LIQUIDITY: u64 = 2;
    const E_NOT_INITIALIZED: u64 = 3;

    struct SwapConfig has key {
        admin: address,
        rate_numerator: u64,
        rate_denominator: u64,
        signer_cap: account::SignerCapability,
    }

    struct LiquidityPool<phantom CoinType> has key {
        coins: Coin<CoinType>,
    }

    public entry fun init(admin: &signer) {
        let admin_addr = signer::address_of(admin);

        let (resource_signer, signer_cap) = account::create_resource_account(admin, b"swap_pool");
        let resource_addr = signer::address_of(&resource_signer);

        move_to(admin, SwapConfig {
            admin: admin_addr,
            rate_numerator: 1,
            rate_denominator: 1,
            signer_cap,
        });

        coin::register<TokenA>(&resource_signer);
        coin::register<TokenB>(&resource_signer);

        move_to(&resource_signer, LiquidityPool<TokenA> {
            coins: coin::zero<TokenA>(),
        });
        move_to(&resource_signer, LiquidityPool<TokenB> {
            coins: coin::zero<TokenB>(),
        });

        if (!coin::is_account_registered<TokenA>(admin_addr)) {
            coin::register<TokenA>(admin);
        };
        if (!coin::is_account_registered<TokenB>(admin_addr)) {
            coin::register<TokenB>(admin);
        };
    }

    public entry fun set_rate(
        admin: &signer,
        numerator: u64,
        denominator: u64
    ) acquires SwapConfig {
        let admin_addr = signer::address_of(admin);
        assert!(exists<SwapConfig>(admin_addr), error::not_found(E_NOT_INITIALIZED));

        let cfg = borrow_global_mut<SwapConfig>(admin_addr);
        assert!(
            admin_addr == cfg.admin,
            error::permission_denied(E_NOT_ADMIN)
        );
        assert!(denominator > 0, error::invalid_argument(4));

        cfg.rate_numerator = numerator;
        cfg.rate_denominator = denominator;
    }

    public entry fun add_liquidity_a(
        admin: &signer,
        amount: u64
    ) acquires SwapConfig, LiquidityPool {
        let admin_addr = signer::address_of(admin);
        assert!(exists<SwapConfig>(admin_addr), error::not_found(E_NOT_INITIALIZED));

        let cfg = borrow_global<SwapConfig>(admin_addr);
        assert!(
            admin_addr == cfg.admin,
            error::permission_denied(E_NOT_ADMIN)
        );

        let resource_signer = account::create_signer_with_capability(&cfg.signer_cap);
        let resource_addr = signer::address_of(&resource_signer);

        let coins = coin::withdraw<TokenA>(admin, amount);
        let pool = borrow_global_mut<LiquidityPool<TokenA>>(resource_addr);
        coin::merge(&mut pool.coins, coins);
    }

    public entry fun add_liquidity_b(
        admin: &signer,
        amount: u64
    ) acquires SwapConfig, LiquidityPool {
        let admin_addr = signer::address_of(admin);
        assert!(exists<SwapConfig>(admin_addr), error::not_found(E_NOT_INITIALIZED));

        let cfg = borrow_global<SwapConfig>(admin_addr);
        assert!(
            admin_addr == cfg.admin,
            error::permission_denied(E_NOT_ADMIN)
        );

        let resource_signer = account::create_signer_with_capability(&cfg.signer_cap);
        let resource_addr = signer::address_of(&resource_signer);

        let coins = coin::withdraw<TokenB>(admin, amount);
        let pool = borrow_global_mut<LiquidityPool<TokenB>>(resource_addr);
        coin::merge(&mut pool.coins, coins);
    }

    public entry fun swap_a_to_b(
        user: &signer,
        amount_in: u64,
        admin_addr: address
    ) acquires SwapConfig, LiquidityPool {
        assert!(exists<SwapConfig>(admin_addr), error::not_found(E_NOT_INITIALIZED));

        let cfg = borrow_global<SwapConfig>(admin_addr);
        let resource_signer = account::create_signer_with_capability(&cfg.signer_cap);
        let resource_addr = signer::address_of(&resource_signer);

        let amount_out = (amount_in * cfg.rate_numerator) / cfg.rate_denominator;

        // Check if user is registered for both coin types
        let user_addr = signer::address_of(user);
        if (!coin::is_account_registered<TokenB>(user_addr)) {
            coin::register<TokenB>(user);
        };

        // Check liquidity
        let pool_b = borrow_global<LiquidityPool<TokenB>>(resource_addr);
        let vault_balance = coin::value(&pool_b.coins);
        assert!(
            vault_balance >= amount_out,
            error::resource_exhausted(E_INSUFFICIENT_LIQUIDITY)
        );

        // Perform swap
        let a_coins = coin::withdraw<TokenA>(user, amount_in);
        let pool_a = borrow_global_mut<LiquidityPool<TokenA>>(resource_addr);
        coin::merge(&mut pool_a.coins, a_coins);

        let pool_b_mut = borrow_global_mut<LiquidityPool<TokenB>>(resource_addr);
        let b_coins = coin::extract(&mut pool_b_mut.coins, amount_out);
        coin::deposit<TokenB>(user_addr, b_coins);
    }

    public entry fun swap_b_to_a(
        user: &signer,
        amount_in: u64,
        admin_addr: address
    ) acquires SwapConfig, LiquidityPool {
        assert!(exists<SwapConfig>(admin_addr), error::not_found(E_NOT_INITIALIZED));

        let cfg = borrow_global<SwapConfig>(admin_addr);
        let resource_signer = account::create_signer_with_capability(&cfg.signer_cap);
        let resource_addr = signer::address_of(&resource_signer);

        // Inverse rate calculation for B to A
        let amount_out = (amount_in * cfg.rate_denominator) / cfg.rate_numerator;

        // Check if user is registered for both coin types
        let user_addr = signer::address_of(user);
        if (!coin::is_account_registered<TokenA>(user_addr)) {
            coin::register<TokenA>(user);
        };

        // Check liquidity
        let pool_a = borrow_global<LiquidityPool<TokenA>>(resource_addr);
        let vault_balance = coin::value(&pool_a.coins);
        assert!(
            vault_balance >= amount_out,
            error::resource_exhausted(E_INSUFFICIENT_LIQUIDITY)
        );

        // Perform swap
        let b_coins = coin::withdraw<TokenB>(user, amount_in);
        let pool_b = borrow_global_mut<LiquidityPool<TokenB>>(resource_addr);
        coin::merge(&mut pool_b.coins, b_coins);

        let pool_a_mut = borrow_global_mut<LiquidityPool<TokenA>>(resource_addr);
        let a_coins = coin::extract(&mut pool_a_mut.coins, amount_out);
        coin::deposit<TokenA>(user_addr, a_coins);
    }

    // View functions
    #[view]
    public fun get_rate(admin_addr: address): (u64, u64) acquires SwapConfig {
        assert!(exists<SwapConfig>(admin_addr), error::not_found(E_NOT_INITIALIZED));
        let cfg = borrow_global<SwapConfig>(admin_addr);
        (cfg.rate_numerator, cfg.rate_denominator)
    }

    #[view]
    public fun get_liquidity_a(admin_addr: address): u64 acquires SwapConfig, LiquidityPool {
        assert!(exists<SwapConfig>(admin_addr), error::not_found(E_NOT_INITIALIZED));
        let cfg = borrow_global<SwapConfig>(admin_addr);
        let resource_signer = account::create_signer_with_capability(&cfg.signer_cap);
        let resource_addr = signer::address_of(&resource_signer);

        let pool = borrow_global<LiquidityPool<TokenA>>(resource_addr);
        coin::value(&pool.coins)
    }

    #[view]
    public fun get_liquidity_b(admin_addr: address): u64 acquires SwapConfig, LiquidityPool {
        assert!(exists<SwapConfig>(admin_addr), error::not_found(E_NOT_INITIALIZED));
        let cfg = borrow_global<SwapConfig>(admin_addr);
        let resource_signer = account::create_signer_with_capability(&cfg.signer_cap);
        let resource_addr = signer::address_of(&resource_signer);

        let pool = borrow_global<LiquidityPool<TokenB>>(resource_addr);
        coin::value(&pool.coins)
    }
}
