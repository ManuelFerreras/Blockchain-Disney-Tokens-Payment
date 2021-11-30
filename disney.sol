pragma solidity >= 0.8.0;

import "./SafeMath.sol";
import "./ERC20.sol";

// SPDX-License-Identifier: UNLICENSED

contract Disney {
    // -------------------------------------------- Variable Declaration -------------------------------------------- //

    using SafeMath for uint;

    // Token Instance.
    ERC20Basic private token;

    // Owner Address
    address payable public owner;

    // Constructor
    constructor () {

        token = new ERC20Basic(10000);
        owner = payable(msg.sender);

    }

    // Data Structure to Store Clients.
    struct client {

        uint boughtTokens;

        string[] payedAttractions;

    }

    // Register clients.
    mapping (address => client) public clients;


    // -------------------------------------------- Tokens Management Logic -------------------------------------------- //


    // Stablish token price.
    function tokenPrice(uint256 _tokensAmount) internal pure returns (uint256) {

        // Returns tokens => ether conversion.
        return _tokensAmount * (1 ether);

    }

    // Buy Tokens Function
    function buyTokens(uint _amount) public payable {

        // Get tokens Price
        uint _cost = tokenPrice(_amount);

        // Check masg.sender has enough ether.
        require (msg.value >= _cost, "Not Enough Ether Sent.");

        // Get restant ether.
        uint _returnValue = msg.value - _cost;

        // Returns that value to msg.sender.
        payable(msg.sender).transfer(_returnValue);

        // Get Disney Tokens Balance of This Contract.
        uint _balance = balanceOf(address(this));
        require(_amount >= _balance, "Contract has not enough tokens.");

        // Transfer
        token.transfer(msg.sender, _amount);

        // Register tokens bought.
        clients[msg.sender].boughtTokens = clients[msg.sender].boughtTokens.add(_amount);

    }

    // Get Disney Contract Tokens Balance.
    function balanceOf(address _owner) public view returns (uint) {
        return token.balanceOf(_owner);
    }

    // Create New Tokens.
    function mintTokens(uint _amount) public onlyOwner{
        token.increaseTotalSupply(_amount);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    // -------------------------------------------- Disney Management Logic -------------------------------------------- //

    // Events:
    event enjoyTransaction(string);
    event newAttraction(string, uint);
    event delAttraction(string);

    // Mapping attractionName => attraction data struct.

    // Attraction data Struct.
    struct attraction {
        string attractionName;
        uint attractionPrice;
        bool attractionState;
    }

    mapping (string => attraction) public attractions;

    // Attractions names array.
    string[] attractionsNames;

    // Mapping client => history.
    mapping (address => string[]) attractionsHistory;

    // Create new Attraction.
    function createNewAttraction(string memory _name, uint _price) public onlyOwner {

        // Create Attraction.
        attractions[_name] = attraction(_name, _price, true);

        // Push its name to attractions names array.
        attractionsNames.push(_name);

        // Emit New attraction created.
        emit newAttraction(_name, _price);

    }

    // Disable Attraction.
    function disableAttraction(string memory _name) public onlyOwner {

        // Change attraction state to false.
        attractions[_name].attractionState = false;

        // Emit disabling State.
        emit delAttraction(_name);

    }

    // Get Attractions.
    function getAttractions() public view returns (string[] memory) {
        return attractionsNames;
    }

    // Enter attraction
    function enterAttraction(string memory _attractionName) public {

        // Get attraction price.
        uint256 _attractionPrice = attractions[_attractionName].attractionPrice;

        // Checks if it is available.
        require(attractions[_attractionName].attractionState == true, "Attraction Not Available.");

        // Checks if clients has enough tokens.
        require(_attractionPrice <= balanceOf(msg.sender), "Not Enough Tokens.");

        // Make the Transfer.
        token.transferFrom(msg.sender, address(this), _attractionPrice);

        // Add attraction to client attractions history.
        attractionsHistory[msg.sender].push(_attractionName);

        // Trigger Events
        emit enjoyTransaction(_attractionName);
        
    }

    // Get clients history
    function getClientHistory(address _client) public view returns (string[] memory) {

        return attractionsHistory[_client];

    }

    // Give back tokens.
    function giveBackTokens(uint _amount) public payable {

        // Check user has enough tokens.
        require(balanceOf(msg.sender) >= _amount, "Not Enough Tokens.");

        // TransferTokens
        token.transferFrom(msg.sender, address(this), _amount);

        // Give Back Ether
        payable(msg.sender).transfer(tokenPrice(_amount));

    }


    // -------------------------------------------- Food Section -------------------------------------------- //


    // Create Food Structure
    struct food {
        string foodName;
        uint foodPrice;
        bool foodState;
    }

    // Array to save food names in.
    string[] foodNames;

    // Maping with food information. name => struct
    mapping (string => food) foods;

    // Mapping with clients food buy history.
    mapping (address => string[]) foodHistory;

    // Events
    event foodCreated(string, uint);
    event foodDisabled(string);
    event foodEnabled(string);
    event foodBought(string, uint, address);


    // Create new Food
    function createNewFood(string memory _foodName, uint _foodPrice) public onlyOwner {

        // Create new food.
        foods[_foodName] = food(_foodName, _foodPrice, true);

        // Trigger Event.
        emit foodCreated(_foodName, _foodPrice);

    }

    // Disable a food.
    function disableFood(string memory _foodName) public onlyOwner {

        // Check if food is enabled.
        require (foods[_foodName].foodState, "Food Already Disabled.");

        // Set Food as Disabled.
        foods[_foodName].foodState = false;

        // Trigger Event.
        emit foodDisabled(_foodName);

    }

    // Enable a food.
    function enableFood(string memory _foodName) public onlyOwner {

        // Check if food is enabled.
        require (!foods[_foodName].foodState, "Food Already Enabled.");

        // Set Food As Enabled.
        foods[_foodName].foodState = true;

        // Trigger Event
        emit foodEnabled(_foodName);

    }

    // Buy Food
    function buyFood(string memory _foodName) public {

        // Gets Food Price.
        uint _foodPrice = foods[_foodName].foodPrice;

        // Checks if client has enough tokens to buy the food.
        require (balanceOf(msg.sender) >= _foodPrice, "Not Enough Tokens");

        // Transfer
        token.transferFrom(msg.sender, address(this), _foodPrice);

        // Add To clients History.
        foodHistory[msg.sender].push(_foodName);

        // Trigger Event
        emit foodBought(_foodName, _foodPrice, msg.sender);

    }

    // Get Client Food History.
    function getFoodHistory(address _client) public view returns (string[] memory) {
        return foodHistory[_client];
    }

}