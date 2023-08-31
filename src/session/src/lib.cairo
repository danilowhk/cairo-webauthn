use core::box::BoxTrait;
use core::array::SpanTrait;
use starknet::info::{
    get_tx_info,
    get_block_timestamp
};
use result::ResultTrait;
use option::OptionTrait;
use array::ArrayTrait;
use core::{
    TryInto, 
    Into
};
use starknet::{
    contract_address::ContractAddress
};

use core::ecdsa::check_ecdsa_signature;
type ValidationResult = Result<(),()>;



#[derive(Copy, Drop, Serde)]
struct TxInfoSignature{
    r: felt252, 
    s: felt252,
    session_key: felt252,
    session_expires: u64,
    root: felt252,
    proof_len: usize,
    proofs_len: usize,
    proofs: Span<felt252>,
    session_token: Span<felt252>
}

trait RevokedSessionKeyStorageTrait<T> {
    fn contains(self: T, key: felt252) -> bool;
    // fn add(self: T, key: felt252) -> Result<(), ()>;
}

impl FeltSpanTryIntoSignature of TryInto<Span<felt252>, TxInfoSignature> {
    // Convert a span of felts to TxInfoSignature struct
    // The layout of the span should look like:
    // [r, s, session_key, session_expires, root, proofs_len, proof_len, { proofs ... } , session_token_len, { session_token ... }]
    //                                                                   ^-proofs_len-^                      ^-session_token_len-^
    // See details in the implementation
    fn try_into(self: Span<felt252>) -> Option<TxInfoSignature> {
        let proofs_len: usize = (*self[7]).try_into()?;
        let session_token_offset: usize = 8 + proofs_len;
        let session_token_len: usize = (*self[session_token_offset]).try_into()?;

        let proofs: Span<felt252> = self.slice(8, 8 + proofs_len);
        let session_token: Span<felt252> = self.slice(session_token_offset + 1, session_token_offset + 1 + session_token_len);

        if self.len() != session_token_offset + 1 + session_token.len() {
            return Option::None(());
        }

        Option::Some(TxInfoSignature {
            r: *self[1],
            s: *self[2],
            session_key: *self[3],
            session_expires: (*self[4]).try_into()?,
            root: *self[5],
            proofs_len: proofs_len,
            proof_len: (*self[6]).try_into()?,
            proofs: proofs,
            session_token: session_token
        })
    }
}

fn validate_session<
    StoreT, 
    impl StoreImpl: RevokedSessionKeyStorageTrait<StoreT>,
    impl SDrop: Drop<StoreT>,
>
(call_array: Array<felt252>, storage: StoreT) -> ValidationResult {
    let tx_info = get_tx_info().unbox();
    let sig: TxInfoSignature = match tx_info.signature.try_into() {
        Option::Some(s) => s,
        Option::None => {
            return Result::Err(());
        }
    };

    if sig.proofs_len != call_array.len() * sig.proof_len {
        return Result::Err(());
    };

    let now = get_block_timestamp();
    if sig.session_expires <= now {
        return Result::Err(());
    }

    let session_hash = compute_session_hash(sig, tx_info.chain_id, tx_info.account_contract_address);

    //TODO: check the validity of the signature

    if storage.contains(sig.session_key) {
        return Result::Err(());
    }

    if check_ecdsa_signature(tx_info.transaction_hash, sig.session_key, sig.r, sig.s) == false {
        return Result::Err(());
    }

    // TODO: Check policy

    Result::Ok(())
}

fn compute_session_hash(signature: TxInfoSignature, chain_id: felt252, account: ContractAddress) -> felt252 {
    //TODO: DO TO 
    0_felt252
}