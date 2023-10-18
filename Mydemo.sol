// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0; 

contract P2Psmartcontract{
    
    struct Prosumer {

        address addr;
        int energystatus; 
        uint balance;
        bool registerstatus;
        uint rewardpoints;
    }

    mapping(address => Prosumer) public prosumers;
    address[] public buyers;  // create a queue for buyers to store addresses
    address[] public sellers; // create a queue for sellers to store addresses
    
    //add a new prosumer and store the address
    function addProsumer(address paddr) internal  {
        
        prosumers[paddr] = Prosumer(paddr,0,0,true,0);
        
    } 
    
    //a function for buying and selling energy
    function tradeEnergy() internal{

        while (buyers.length > 0 && sellers.length >0){

            address buyeraddr = buyers[0];
            address selleraddr = sellers[0];
            uint amountbuyer = uint(prosumers[buyeraddr].energystatus * -1);
            uint amountseller = uint(prosumers[selleraddr].energystatus);
            uint perenergy = 1000000000000000000;
            if(amountbuyer > amountseller){
                uint amountbuyerleft = amountbuyer - amountseller;
                prosumers[buyeraddr].energystatus = int(amountbuyerleft) * -1;
                prosumers[selleraddr].energystatus = 0;
                prosumers[buyeraddr].balance = prosumers[buyeraddr].balance - amountseller*perenergy;
                prosumers[selleraddr].balance = prosumers[selleraddr].balance + amountseller*perenergy;
                prosumers[buyeraddr].rewardpoints += amountseller;
                prosumers[selleraddr].rewardpoints += amountseller;
                removefirstseller();
            }
            else if(amountbuyer < amountseller){
                uint amountsellerleft = amountseller - amountbuyer;
                prosumers[selleraddr].energystatus = int(amountsellerleft);
                prosumers[buyeraddr].energystatus = 0;
                prosumers[selleraddr].balance =  prosumers[selleraddr].balance + amountbuyer*perenergy;
                prosumers[buyeraddr].balance =  prosumers[buyeraddr].balance - amountbuyer*perenergy;
                prosumers[buyeraddr].rewardpoints += amountbuyer;
                prosumers[selleraddr].rewardpoints += amountbuyer;
                removefirstbuyer();
            } 
            else {
                prosumers[selleraddr].energystatus = 0;
                prosumers[buyeraddr].energystatus = 0;
                prosumers[selleraddr].balance = prosumers[selleraddr].balance + amountseller*perenergy;
                prosumers[buyeraddr].balance =  prosumers[buyeraddr].balance - amountbuyer*perenergy;
                prosumers[buyeraddr].rewardpoints += amountbuyer;
                prosumers[selleraddr].rewardpoints += amountseller;
                removefirstbuyer();
                removefirstseller();
            }
        }
        

    } 
    
    // a function which is used to remove the address of a buyer from the buyer queue
    function removefirstbuyer() internal{

        for (uint i = 0; i<buyers.length-1; i++){
            buyers[i] = buyers[i+1];
        } 
        buyers.pop();
    
    } 
    
    // a function which is used to remove the address of a seller from the seller queue
    function removefirstseller() internal{

        for (uint i = 0; i<sellers.length-1; i++){
            sellers[i] = sellers[i+1];
        }
        sellers.pop();
    }

    

}




contract Mainsmartcontract is P2Psmartcontract{ 
    
    // a modifier to make sure a prosumer is registered in the system before sending any request.
    modifier isRegistered(address paddr){

        require(prosumers[paddr].registerstatus == true, "the user has not registered");
        _;
  
    }
    
    // a modifier to ensure single registration of a prosumer 
    modifier hasRegistered(address paddr){

        require(prosumers[paddr].registerstatus == false, "the user has registered, cannot register again");
        _;

    }
    
    // a modifier to check whether a buyer has deposited sufficient funds 
    modifier hassufficientfunds(address paddr,int energyamount){

        if (energyamount < 0){
           
           uint perenergy = 1000000000000000000;
           require(prosumers[paddr].balance >= uint(energyamount * -1)*perenergy, "the user needs more balance");
           

        }
        _;

    }
    
    // a public function for registering
    function register() public hasRegistered(msg.sender){

        P2Psmartcontract.addProsumer(msg.sender);
        
    } 
    
    // a function for users to add funds before buying energy
    function addFunds() public payable isRegistered(msg.sender){

        prosumers[msg.sender].balance += msg.value; 
                              
    }
    
    // a public function to accept prosumers’ requests and pass the data to the P2P smart contract
    function submitRequest(int energyamount) public isRegistered(msg.sender) hassufficientfunds(msg.sender,energyamount){

        prosumers[msg.sender].energystatus = energyamount;
        if (energyamount < 0) {
            buyers.push(msg.sender);
            prosumers[msg.sender].energystatus = energyamount;
        }
        else if(energyamount > 0){
            sellers.push(msg.sender);
            prosumers[msg.sender].energystatus = energyamount;
        } 
        P2Psmartcontract.tradeEnergy();

    } 
    
    // a function for prosumers to check the energy status
    function checkenergystatus() public isRegistered(msg.sender) view returns(int){

        return (prosumers[msg.sender].energystatus);

    }
    
    // a function for prosumers to check the balance in Ether(not wei)
    function checkbalance() public isRegistered(msg.sender) view returns(uint){

        return (prosumers[msg.sender].balance/1000000000000000000);

    } 
    
    // a function to withdraw the Ethers from smart wallets of prosumers
    function withdraw() public isRegistered(msg.sender){

        uint amount = prosumers[msg.sender].balance;
        prosumers[msg.sender].balance -= amount; 
        address payable payablesender = payable(msg.sender);
        payablesender.transfer(amount);

    } 

    
    // a function to check the reward points after buying or selling the energy (this will be discussed in the report)
    function checkreward() public isRegistered(msg.sender) view returns(uint){

        return (prosumers[msg.sender].rewardpoints);

    } 

    
    
} 
