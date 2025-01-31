import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can submit permit application",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('building-permit', 'submit-permit-application', [
                types.ascii("123 Main St"),
                types.ascii("RESIDENTIAL_NEW"),
                types.uint(100)
            ], user1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
    }
});

Clarinet.test({
    name: "Only admin can approve permits",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('building-permit', 'submit-permit-application', [
                types.ascii("123 Main St"),
                types.ascii("RESIDENTIAL_NEW"),
                types.uint(100)
            ], user1.address),
            Tx.contractCall('building-permit', 'approve-permit', [
                types.uint(1)
            ], deployer.address),
            Tx.contractCall('building-permit', 'approve-permit', [
                types.uint(1)
            ], user1.address)
        ]);
        
        block.receipts[1].result.expectOk().expectBool(true);
        block.receipts[2].result.expectErr().expectUint(102);
    }
});

Clarinet.test({
    name: "Can get permit details",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const user1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('building-permit', 'submit-permit-application', [
                types.ascii("123 Main St"),
                types.ascii("RESIDENTIAL_NEW"),
                types.uint(100)
            ], user1.address),
            Tx.contractCall('building-permit', 'get-permit', [
                types.uint(1)
            ], user1.address)
        ]);
        
        const permit = block.receipts[1].result.expectOk().expectSome();
        assertEquals(permit['status'], types.ascii("PENDING"));
        assertEquals(permit['property-address'], types.ascii("123 Main St"));
    }
});
