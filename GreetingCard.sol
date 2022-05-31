pragma solidity >=0.6.0 <0.9.0;
//SPDX-License-Identifier: UNLICENSED

/**
 * @title TheGivingKind Greeting Cards NFT
 * @author Maccs Universal.
 * @notice Simpled contract used for minting gift cards to which gifters can deposit ETH as 
 * @notice a gift in the card.
 * @dev Implemented using a modified version of the ERC721 contract from openzeppelin.
 * @dev _owners, _balances & _tokenApprovals variables have visibility has been modified to inherit from private
 * @dev for the overriding of the _transfer function.
 * @dev Also implemented using ERC721URIStorage which inherits the ERC721 contract. 
 * @dev Greeting Card inherits ERC721URIStorage.
 */


// Write tests.
// deploy using remix
// start writing front end.

//Extras
//compare messages using bytes conversion abi.encoded to see if message was altered.

import "./ERC721URIStorage.sol";

contract GreetingCard is ERC721URIStorage{

    /**
     * @notice Card struct 
     * @dev contains current attributes of the NFT card: recipient, balance, message & a message locker.
     */
    struct Card{
        address recipient;
        uint256 balance;
        string message;
        bool message_locked;
    }

    /**
     * @notice Receivers struct 
     * @dev contains current attributes card owners: sender, tokenId.
     */
     struct Locker{
         address sender;
         uint cardId;
     }

    uint private tokenId;

    bool private reEntrancyMutex = false;

    mapping(address => uint) private _receivedCounter;

    /** 
     * @notice map that makes up a locker of all cards currently held by address.
     */
    mapping(address => mapping(uint => Locker)) public _locker; 

    /** 
     * @notice mapping that uses the tokenID as the key and the Card struct variables as values.
     */
    mapping (uint => Card) public _cards;

    /** 
     * @notice modifier checks if call sender is the card owner.
     * @param _tokenId needed to check struct variable.
     */
    modifier isCardOwner(uint _tokenId){
        require(_cards[_tokenId].recipient == msg.sender, "Only the owner of this card can call this function");
        _;
    }

    /** 
    * @notice checks if card message is locked from editing.
    * @dev users can never edit message if requirement is not met.
    * @param _tokenId needed to check struct variable.
    */
    modifier isMessageLocked(uint _tokenId){
        require(_cards[_tokenId].message_locked != true, "The message on this card is locked so it cannot be changed");
        _;
    }

    /** 
    * @notice emits when message is locked.
    * @dev emitted when lockMessage function is called.
    * @param _tokenId card identifier.
    * @param _locked allows user to lock message at minting.
    * @param _lockedBy address that called the function.
    */
    event LockMessage(uint indexed _tokenId, bool indexed _locked, address indexed _lockedBy);

    /** 
    * @notice emits when new card is minted.
    * @dev emitted when newCard function is called.
    * @param _to address the card is minted to.
    * @param _amount ETH deposited to the card.
    * @param _tokenId card identifier.
    * @param _locked allows user to lock message at minting.
    * @param _tokenURI URI for card metsadata.
    */
    event NewCardMinted(address indexed _to, uint256 indexed _amount, uint indexed _tokenId, bool _locked, string _tokenURI);
    
    /** 
    * @notice emits when message is altered.
    * @dev emitted when changeMessage function is called.
    * @param _message new message.
    * @param _tokenId card identifier.
    */
    event MessageChanged(string indexed _message, uint indexed _tokenId);

    /** 
    * @notice emits when card balance is transferred from one card to another.
    * @dev emitted when transferCardBalance function is called.
    * @param _from card id the ETH is transferred from.
    * @param _to card id the ETH is transferred to.
    * @param _amount transferred across _to.
    */
    event CardBalanceTransfer(uint indexed _from, uint indexed _to, uint256 _amount);

    /** 
    * @notice emits when card balance is withdrawn to external address.
    * @dev emitted when withdrawBalance function is called.
    * @param _to address to withdraw fund to.
    * @param _amount to withdraw.
    */
    event Withdraw(address indexed _to, uint256 indexed _amount);

    /** 
    * @notice emits when card balance is topped up.
    * @dev emitted when DepositBalance function is called.
    * @param _from address the deposit comes from.
    * @param _tokenId card identifier.
    * @param _amount deposited.
    */
    event Deposit(address indexed _from, uint indexed _tokenId, uint256 indexed _amount);

    /** 
    * @notice emits when card is transferred from owner to recipient.
    * @dev emitted when transferCard function is called.
    * @param _from address the card is transferred from.
    * @param _to address the card is transferred to.
    * @param _tokenId card identifier.
    */
    event CardTransfer(address indexed _from, address indexed _to, uint indexed _tokenId);

    /** 
    * @notice emits when card is transferred from current locker to the recipients locker.
    * @dev emitted when updateLocker function is called.
    * @param _from address the card is transferred from.
    * @param _to address the card is transferred to.
    * @param _tokenId card identifier.
    */
    event LockerUpdated(address indexed _from, address indexed _to, uint indexed _tokenId);

    constructor () ERC721("TheGivingKind Card","CARD"){
        tokenId = 0;
    }

    /** 
    * @notice Mints a new card.
    * @dev uses _safeMint & _setTokenURI functions from ERC721URIStorage.
    * @param _to address card is minted to.
    * @param _message written in card from minter to recipient.
    * @param _locked locks message in card.
    * @param _tokenURI string linked to card metadata.
    */
    function newCard(address _to, string memory _message, bool _locked, string memory _tokenURI) public payable returns(bool){
        tokenId++;
        _cards[tokenId].recipient = _to;
        _cards[tokenId].balance += msg.value; 
        _cards[tokenId].message = _message;
        _cards[tokenId].message_locked = _locked; 
        _receivedCounter[_to] = _receivedCounter[_to] + 1;
        _locker[_to][_receivedCounter[_to]].cardId = tokenId;
        _locker[_to][_receivedCounter[_to]].sender = msg.sender;
        _safeMint(_to, tokenId);   
        _setTokenURI(tokenId, _tokenURI);
        emit NewCardMinted(_to, msg.value, tokenId, _locked, _tokenURI);
        return true;
    } 

    /** 
    * @notice locked message in card.
    * @dev recipient/owner of card is unable to alter the message in the card.
    * @param _tokenId card identifier.
    */
    function lockMessage(uint _tokenId) public isCardOwner(_tokenId) isMessageLocked(_tokenId) returns(bool){
        _cards[_tokenId].message_locked = true;
        emit LockMessage(_tokenId, _cards[_tokenId].message_locked, msg.sender);
        return true;
    }

    /** 
    * @notice checks if message is locked.
    * @dev returns true/false.
    * @param _tokenId card identifier.
    */
    function MessageLockedStatus(uint _tokenId) view public returns(bool){
        return _cards[_tokenId].message_locked;
    }

    /** 
    * @notice changes card messages.
    * @dev checks if message is locked.
    * @dev we could check the message is actually altered by comparing bytes conversion.
    * @param _message to be replace existing message.
    * @param _tokenId card identifier.
    */
    function changeMessage(string memory _message, uint _tokenId) public isCardOwner(_tokenId) isMessageLocked(_tokenId) returns(bool){
        _cards[_tokenId].message = _message;
        emit MessageChanged(_cards[_tokenId].message, _tokenId);
        return true;
    }

    function getCardMessage(uint _tokenId) view public returns(string memory){
        return _cards[_tokenId].message;
    }

    /** 
    * @notice check card balance.
    * @param _tokenId card identifier.
    */
    function cardBalanceOf(uint _tokenId) view public returns(uint256){
        return _cards[_tokenId].balance;
    }

    /** 
    * @notice transfers balance from one card to another.
    * @param _fromTokenId card identifier of sender card.
    * @param _toTokenId card identifier of recipient card.
    * @param _amount to be transferred.
    */
    function transferCardBalance(uint _fromTokenId, uint _toTokenId, uint256 _amount) public isCardOwner(_fromTokenId) returns(bool){
        require(_fromTokenId != _toTokenId, "You cannot transfer your balance to the same Card.");
        require(_amount <= _cards[_fromTokenId].balance, "Insufficient balance to make this transfer.");
        _cards[_fromTokenId].balance -= _amount;
        _cards[_toTokenId].balance += _amount;
        emit CardBalanceTransfer(_fromTokenId, _toTokenId, _amount);
        return true;
    }

    /** 
    * @notice allows card owner to withdraw card balance to owners address.
    * @dev uses reEntrancyMutex to stop forced reEntry from an external contracts fallback function.
    * @param _tokenId card identifier.
    * @param _to address to receive funds.
    * @param _amount to be withdrawn.
    */
    function withdrawBalance(uint _tokenId, address payable _to, uint256 _amount) public isCardOwner(_tokenId) returns(bool){
        require(!reEntrancyMutex);
        require(_amount <= _cards[_tokenId].balance, "Insufficient balance to make this withdrawal.");
        _cards[_tokenId].balance -= _amount;
        reEntrancyMutex = true;
        _to.transfer(_amount);
        reEntrancyMutex = false;
        emit Withdraw(_to,_tokenId);
        return true;
    }

    /** 
    * @notice deposits funds to card balance.
    * @dev transfers funds from 'msg.sender' to '_cards[_tokenId].balance'.
    * @param _tokenId card identifier.
    */
    function depositBalance(uint _tokenId) public payable returns(bool){
        require(msg.value > 0, "You cannot deposit '0' value to a card");
        _cards[_tokenId].balance += msg.value;
        emit Deposit(msg.sender, _tokenId, msg.value);
        return true;
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 _tokenId
    ) internal override {
        require(ERC721.ownerOf(_tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, _tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), _tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[_tokenId] = to;
        transferCard(from, to, _tokenId);
        updateLocker(from, to, _tokenId);

        emit Transfer(from, to, _tokenId);
    }

    /**
     * @notice changes card recipient when a transfer is made.
     * @param _from address the card is transferred from.
     * @param _to address the card is transferred to.
     * @param _tokenId card identifier. 
    */
    function transferCard(address _from, address _to, uint _tokenId) private returns(bool){
        _cards[_tokenId].recipient = _to;
        emit CardTransfer(_from, _to, _tokenId);
        return true;
    }

    /**
     * @notice updates recipient's locker when a card transfer is made.
     * @param _from address the card is transferred from.
     * @param _to address the card is transferred to.
     * @param _tokenId card identifier. 
    */
    function updateLocker(address _from, address _to, uint _tokenId) private returns(bool){
        uint i;
        for(i = 0; i < _receivedCounter[_from]; i++){
            if(_locker[_from][i+1].cardId == _tokenId){
                _locker[_from][i+1].cardId = 0;
                _receivedCounter[_to]++;
                _locker[_to][_receivedCounter[_to]].sender = _from;
                _locker[_to][_receivedCounter[_to]].cardId = _tokenId;
            }
        }
        emit LockerUpdated(_from, _to, _tokenId);
        return true;
    }

    /** 
     * @notice returns all cards in the locker.
     * @dev uses msg.sender to reference the account that owns the cards in the Locker.
    */
    function openLocker() view public returns(address[] memory, uint[] memory){
        uint i; 

        address[] memory senders = new address[](_receivedCounter[msg.sender]);
        uint[] memory cardIds = new uint[](_receivedCounter[msg.sender]);
         
        for(i = 0; i < _receivedCounter[msg.sender]; i++){
            senders[i] = _locker[msg.sender][i+1].sender;
            cardIds[i] = _locker[msg.sender][i+1].cardId;
        }

        return(senders, cardIds);
    } 

    /** 
    * @notice returns current state of the tokenId counter.
    */
    function getCurrentId() view public returns(uint){
        uint counter =   tokenId;
        return counter;
    }

  fallback () external payable{}

  receive () external payable{
    require(msg.sender.balance >= msg.value,
          "Insufficient balance to complete transaction.");
  }

}