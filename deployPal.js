const {
    Client,
    AccountId,
    PrivateKey,
    ContractCreateFlow,
    ContractFunctionParameters,
    ContractCreateTransaction,
    ContractExecuteTransaction,
    AccountCreateTransaction,
    Hbar,
    FileCreateTransaction
} = require('@hashgraph/sdk');
const fs = require('fs');

require("dotenv").config();

//Import the compiled contract from the pal.json file
let PalToken = require("./jsonFiles/pal.json");

console.log(process.env.ACCOUNT_ID, process.env.PRIVATE_KEY);

const operatorId = AccountId.fromString(process.env.ACCOUNT_ID);
const operatorKey = PrivateKey.fromString(process.env.PRIVATE_KEY);

const client = Client.forTestnet().setOperator(operatorId, operatorKey);

const main = async () => {
    try{

        const bytecode = PalToken.object;
        console.log(0);

        const contractCreate = new ContractCreateFlow()
            .setGas(100000)
            .setBytecode(bytecode);
            
        console.log(1);
        //Sign the transaction with the client operator key and submit to a Hedera network
        const txResponse = contractCreate.execute(client);
        
        console.log(2);
        //Get the receipt of the transaction
        const receipt = (await txResponse).getReceipt(client);

        console.log(3);
        //Get the file ID from the receipt
        const bytecodeFileId = receipt.fileId;

        //Log the file ID
        console.log("The smart contract byte code file ID is " + bytecodeFileId)

        // Instantiate the contract instance
        const contractTx = await new ContractCreateTransaction()
            //Set the file ID of the Hedera file storing the bytecode
            .setBytecodeFileId(bytecodeFileId)
            //Set the gas to instantiate the contract
            .setGas(100000)
            //Provide the constructor parameters for the contract
            .setConstructorParameters(new ContractFunctionParameters()
                .addAddress(operatorId.toSolidityAddress())
                .addUint256(100000)
            );

        //Submit the transaction to the Hedera test network
        const contractResponse = await contractTx.execute(client);

        //Get the receipt of the file create transaction
        const contractReceipt = await contractResponse.getReceipt(client);

        //Get the smart contract ID
        const newContractId = contractReceipt.contractId;

        //Log the smart contract ID
        console.log("The smart contract ID is " + newContractId);

        //v2 JavaScript SDK
    }
    catch(error){
        console.log(error);
        return;
    }
}

main();