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
    name: "Can pay permit fees",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('building-permit', 'submit-permit-application', [
                types.ascii("123 Main St"),
                types.ascii("RESIDENTIAL_NEW"),
                types.uint(100)
            ], user1.address),
            Tx.contractCall('building-permit', 'pay-permit-fees', [
                types.uint(1)
            ], user1.address)
        ]);
        
        block.receipts[1].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Can extend permit",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('building-permit', 'submit-permit-application', [
                types.ascii("123 Main St"),
                types.ascii("RESIDENTIAL_NEW"),
                types.uint(100)
            ], user1.address),
            Tx.contractCall('building-permit', 'extend-permit', [
                types.uint(1),
                types.uint(200)
            ], user1.address)
        ]);
        
        block.receipts[1].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Only admin can approve permits with paid fees",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('building-permit', 'submit-permit-application', [
                types.ascii("123 Main St"),
                types.ascii("RESIDENTIAL_NEW"),
                types.uint(100)
            ], user1.address),
            Tx.contractCall('building-permit', 'pay-permit-fees', [
                types.uint(1)
            ], user1.address),
            Tx.contractCall('building-permit', 'approve-permit', [
                types.uint(1)
            ], deployer.address),
            Tx.contractCall('building-permit', 'approve-permit', [
                types.uint(1)
            ], user1.address)
        ]);
        
        block.receipts[2].result.expectOk().expectBool(true);
        block.receipts[3].result.expectErr().expectUint(102);
    }
});
