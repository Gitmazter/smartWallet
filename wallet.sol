// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error InvalidAmount(uint256 sent, uint256 minRequired);
error InsufficientBalance(uint256 requestedAmount, uint256 balance);



contract Trier {
  function sufficientBalance(uint256 balance,uint256 amount) public pure {
    require(balance >= amount);
  }

  function RequiresAmountOverMin(uint256 amount) public pure {
    require(amount > 0);
  }
}


contract SimpleWallet {
    mapping(address => User) users;
    uint minRequired;
    Trier public trier;

    //Constructor to set min amounts and to deploy external contract
    constructor (uint256 _minRequired) {
      minRequired = _minRequired;
      trier = new Trier();
    }
    // struct for users
    struct User {
        uint256 balance;
    }

    // Events to log deposit withdrawal and transfer actions
    event Deposited   (address indexed account, uint256 amount);
    event Withdrawn   (address indexed account, uint256 amount);
    event Transferred (address indexed from, address indexed to, uint256 amount);
    event Log         (string message);

    // Modifier to check if the user exists
    modifier userExists(address user) {
        require(users[user].balance > 0, "User Not Found");
        _;
    }

    // Modifier to check if the user has a sufficient balance
    modifier sufficientBalance(uint256 amount) {
        require(users[msg.sender].balance >= amount, "Insufficient balance.");
        _;
    }

    // Function to deposit Ether with try catch
    function DepositWithTryCatch () public payable {
      try trier.RequiresAmountOverMin(msg.value) {
        // amount is good;
        User storage user = users[msg.sender];
        user.balance += msg.value;
        emit Deposited(msg.sender, msg.value);
      }
      catch {
        // amount is no-good 
        // revert with error message
        revert InvalidAmount ({
          sent: msg.value,
          minRequired: minRequired
        });
      }
    }


    // Function to withdraw Ether with try catch
    function Withdraw(uint256 amount) public payable userExists(msg.sender) {
      // user exists
      User storage user = users[msg.sender];
      try trier.sufficientBalance(user.balance, amount) {
        // balance is good
        user.balance -= amount;
        require(payable(msg.sender).send(amount), "Failed to send Ether.");
        emit Withdrawn(msg.sender, amount);
      }
      catch {
        // balance is no-good
        // revert with error message
        revert InsufficientBalance({
          requestedAmount: amount,
          balance: user.balance
        });
      }
    }


    // Function to transfer between known accounts with try catch,
    function Transfer(uint256 amount, address recipient ) public userExists(recipient) userExists(msg.sender) {
      // users exist
      User storage sender = users[msg.sender];
      User storage receiver = users[recipient];

      try trier.sufficientBalance(sender.balance, amount) {
        // balance is good
        sender.balance -= amount;
        receiver.balance += amount;
        
        emit Transferred(msg.sender, recipient ,amount);
      }   
      catch {
        // balance is no-good
        // revert with error message
        revert InsufficientBalance({
          requestedAmount: amount,
          balance: sender.balance
        });
      }
    }

    // Function to check balance for personal accounts
    function checkBalance() public view returns (uint256) {
        return users[msg.sender].balance;
    }
}