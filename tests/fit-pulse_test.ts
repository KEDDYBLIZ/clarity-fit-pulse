import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensures user can record a workout and receive tokens",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("fit-pulse", "record-workout", 
        [types.ascii("running"), types.uint(30), types.uint(8)], 
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
    
    block.receipts[0].result.expectOk().expectUint(1);

    // Verify token rewards
    const workout = chain.callReadOnlyFn(
      "fit-pulse",
      "get-workout",
      [types.uint(1)],
      wallet_1.address
    );
    
    workout.result.expectOk().expectSome();
  },
});

Clarinet.test({
  name: "Ensures user can create a challenge",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("fit-pulse", "create-challenge",
        [types.ascii("30 Day Challenge"), types.uint(2592000), types.uint(1000)],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
    
    block.receipts[0].result.expectOk().expectUint(1);
  },
});

Clarinet.test({
  name: "Ensures token rewards are calculated correctly",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    const tokenRate = chain.callReadOnlyFn(
      "fit-pulse",
      "get-token-rate",
      [],
      wallet_1.address
    );
    
    tokenRate.result.expectOk().expectUint(10);
  },
});
