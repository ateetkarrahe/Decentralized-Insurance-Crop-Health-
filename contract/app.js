// app.js

const contractABI = [/* Paste your ABI here */];
const contractAddress = '0xcCa8cff07cC9F21E8f5B310F868e83838571F6A4';

let insuranceContract;
let userAccount;

window.addEventListener('load', async () => {
    if (window.ethereum) {
        window.web3 = new Web3(window.ethereum);
        try {
            await window.ethereum.request({ method: 'eth_requestAccounts' });
            const accounts = await web3.eth.getAccounts();
            userAccount = accounts[0];

            insuranceContract = new web3.eth.Contract(contractABI, contractAddress);

            console.log("Connected account:", userAccount);
            updateUI();
        } catch (error) {
            console.error("User denied account access", error);
        }
    } else {
        alert('Please install MetaMask to use this app.');
    }
});

async function purchasePolicy(policyType, premiumInEther) {
    const premium = web3.utils.toWei(premiumInEther, 'ether');
    await insuranceContract.methods.purchasePolicy(policyType).send({
        from: userAccount,
        value: premium
    });
    alert('Policy purchased!');
    updateUI();
}

async function fileClaim() {
    await insuranceContract.methods.fileClaim().send({ from: userAccount });
    alert('Claim filed!');
    updateUI();
}

async function cancelPolicy() {
    await insuranceContract.methods.cancelPolicy().send({ from: userAccount });
    alert('Policy canceled.');
    updateUI();
}

async function donate(amountInEther) {
    const amount = web3.utils.toWei(amountInEther, 'ether');
    await insuranceContract.methods.donate().send({ from: userAccount, value: amount });
    alert('Donation successful.');
}

async function extendPolicy(extraDays, paymentEther) {
    const payment = web3.utils.toWei(paymentEther, 'ether');
    await insuranceContract.methods.extendPolicy(extraDays).send({
        from: userAccount,
        value: payment
    });
    alert('Policy extended.');
}

async function renewPolicy(premiumInEther) {
    const premium = web3.utils.toWei(premiumInEther, 'ether');
    await insuranceContract.methods.renewPolicy().send({
        from: userAccount,
        value: premium
    });
    alert('Policy renewed.');
    updateUI();
}

async function updateUI() {
    const policy = await insuranceContract.methods.getPolicyDetails(userAccount).call();
    const contractBalance = await insuranceContract.methods.getContractBalance().call();
    document.getElementById('policyInfo').innerText = `
        Type: ${policy.policyType}
        Premium: ${web3.utils.fromWei(policy.premium, 'ether')} ETH
        Coverage: ${web3.utils.fromWei(policy.coverage, 'ether')} ETH
        Status: ${['None', 'Filed', 'Approved', 'Rejected'][policy.claimStatus]}
        Active: ${policy.isActive}
        Expiry: ${new Date(policy.expiry * 1000).toLocaleString()}
    `;

    document.getElementById('contractBalance').innerText =
        `Contract Balance: ${web3.utils.fromWei(contractBalance, 'ether')} ETH`;
}
