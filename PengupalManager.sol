// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.13;

import "./PenguinNFT.sol";
import "./PalToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PengupalManager is Ownable {

    using SafeMath for uint256;

    struct UserInfo {
        uint256 tokenId;
        uint256 startBlock;
    }

    address pengupalsManagerAddress;
    address penguinNFTaddress;
    address PalTokenAddress;

    bool _status;
    uint256 public RewardTokenPerBlock;
    uint256 private collectionMaxNFTNumber;
    uint8 public multiplyerForGoldenReward;

    mapping(string => bool) _tokenHashExists;
    mapping(address => UserInfo[]) public userInfo;
    mapping(address => uint256) public stakingAmount;

    event Received(address addr, uint amount);
    event Fallback(address addr, uint amount);
    event ChangeEvoNFTAddress(address newddr);
    event ChangePalTokenAddress(address newddr);
    event ChangeMintingFee(uint256 fee);
    event SingleMintingHappend(address addr);
    event MultipleMintingHappend(address addr, uint256 count);
    event OwnerIsChanged(address addr);
    event TransferFunds(address addr, uint256 amount, uint8 kind);
    event EvoCollectionUriChanged(address addr, string collectionUri);
    event Stake(address indexed user, uint256 amount);
    event UnStake(address indexed user, uint256 amount);
    event ChangeMintingCounterValue(uint256 count);
    event ChangeCollectionNFTNumber(uint256 amount);
    
    constructor(address _nftAddress, address _evoAddress,  uint256 _maxNFTNumber) {
        pengupalsManagerAddress = msg.sender;
        penguinNFTaddress = _nftAddress;
        PalTokenAddress = _evoAddress;
        _status = false;
        RewardTokenPerBlock = 40 ether;
        collectionMaxNFTNumber = _maxNFTNumber;
        multiplyerForGoldenReward = 2;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable { 
        emit Fallback(msg.sender, msg.value);
    }

    modifier nonReentrant() {
        require(_status != true, "ReentrancyGuard: reentrant call");
        _status = true;
        _;
        _status = false;
    }

    function setMultiplyerForGoldenReward(uint8 _multiplier) external onlyOwner{
        multiplyerForGoldenReward = _multiplier;
    }

    function getEvoCollectionUri() public view returns(string memory){
        return PenguinNFT(payable(penguinNFTaddress)).getBaseuri();
    }

    function setEvoCollectionUri(string memory _newUri) external onlyOwner {      
        emit EvoCollectionUriChanged(msg.sender, _newUri);
        PenguinNFT(payable(penguinNFTaddress)).setBaseUri(_newUri);
    }

    function setEvoNFTaddress(address _addr) external onlyOwner{
        require(_addr != address(0), "Invalid address...");
        penguinNFTaddress = _addr;
        emit ChangeEvoNFTAddress(_addr);
    }

    function getEvoNFTAddress() view external returns(address){
        return penguinNFTaddress;
    }

    function setPalTokenAddress(address _addr) external onlyOwner{
        require(_addr != address(0), "Invalid address...");
        PalTokenAddress = _addr;
        emit ChangePalTokenAddress(_addr);
    }

    function getPalTokenAddress() view external returns(address){
        return PalTokenAddress;
    }

    function setMaxNftNumber(uint256 _amount) external onlyOwner {
        require(_amount >= 0, "Invalid max number.");
        collectionMaxNFTNumber = _amount;
        emit ChangeCollectionNFTNumber(collectionMaxNFTNumber);
    }

    function getMaxNftNumber()  view external returns(uint256) {
        return collectionMaxNFTNumber;
    }

    function getWithdrawBalance(uint8 _kind) public  view returns (uint256) {
        require(_kind >= 0, "Invalid cryptocurrency...");

        if (_kind == 0) {
          return address(this).balance;
        } else {
          return PalToken(PalTokenAddress).balanceOf(address(this));
        }
    }

    function setOwner(address payable _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid input address...");
        pengupalsManagerAddress = _newOwner;
        transferOwnership(pengupalsManagerAddress);
        emit OwnerIsChanged(pengupalsManagerAddress);
    }

    function customizedTransfer(address payable _to, uint256 _amount, uint8 _kind) internal {
        require(_to != address(0), "Invalid address...");
        require(_amount >= 0, "Invalid transferring amount...");
        require(_kind >= 0, "Invalid cryptocurrency...");
        
        if (_kind == 0) {
          _to.transfer(_amount);
        } else {
          PalToken(PalTokenAddress).transfer(_to, _amount);
        }
        emit TransferFunds(_to, _amount, _kind);
    }

    function withDraw(uint256 _amount, uint8 _kind) external onlyOwner {
        require(_amount > 0, "Invalid withdraw amount...");
        require(_kind >= 0, "Invalid cryptocurrency...");
        require(getWithdrawBalance(_kind) > _amount, "None left to withdraw...");

        customizedTransfer(payable(msg.sender), _amount, _kind);
    }

    function withDrawAll(uint8 _kind) external onlyOwner {
        require(_kind >= 0, "Invalid cryptocurrency...");
        uint256 remaining = getWithdrawBalance(_kind);
        require(remaining > 0, "None left to withdraw...");

        customizedTransfer(payable(msg.sender), remaining, _kind);
    }

    function changeRewardTokenPerBlock(uint256 _RewardTokenPerBlock) external onlyOwner{
        RewardTokenPerBlock = _RewardTokenPerBlock;
    }

    function pendingReward(address _user, uint256 _tokenId) public view returns (uint256) 
    {
        (bool _isStaked, uint256 _startBlock) = getStakingItemInfo(_user, _tokenId);
        if(!_isStaked) return 0;
        uint256 currentBlock = block.number;

        uint256 rewardAmount = (currentBlock.sub(_startBlock)).mul(RewardTokenPerBlock);
        return rewardAmount;
    }

    function getStakingInfoOfUser(address _user) public view returns(uint256[] memory , uint256[] memory , string[] memory)
    {
        uint256[] memory nftIds = new uint256[](userInfo[_user].length);
        uint256[] memory rewards = new uint256[](userInfo[_user].length);
        string[] memory tokenUris = new string[](userInfo[_user].length);
        uint256 tempId;
        for (uint256 i = 0; i < userInfo[_user].length; i++) 
        {
            tempId = userInfo[_user][i].tokenId;
            nftIds[i] = tempId;
            rewards[i] = pendingReward(_user, tempId);
            tokenUris[i] = PenguinNFT(payable(penguinNFTaddress)).tokenURI(tempId);
        }
        return (nftIds, rewards, tokenUris);
    }

    function getTokenURIsFromIds(uint256[] memory _tokenIds) public view returns(string[] memory)
    {        
        string[] memory tokenUris = new string[](_tokenIds.length);   
        for (uint256 i = 0; i < _tokenIds.length; i++) 
        {
            tokenUris[i] = PenguinNFT(payable(penguinNFTaddress)).tokenURI(_tokenIds[i]);
        }
        return tokenUris;
    }

    function pendingTotalReward(address _user) public view returns(uint256) 
    {
        uint256 pending = 0;        
        uint256 goldenNFTcount = PenguinNFT(payable(penguinNFTaddress)).getCountOfGldenNFT(_user);        
        for (uint256 i = 0; i < userInfo[_user].length; i++) {
            uint256 temp = pendingReward(_user, userInfo[_user][i].tokenId);      
            temp = temp.mul(goldenNFTcount).mul(multiplyerForGoldenReward);
            pending = pending.add(temp);
        }                
        return pending;
    }

    function stake(uint256[] memory tokenIds) public 
    {
        for(uint256 i = 0; i < tokenIds.length; i++) 
        {
            (bool _isStaked,) = getStakingItemInfo(msg.sender, tokenIds[i]);
            if(_isStaked) continue;
            if(PenguinNFT(payable(penguinNFTaddress)).ownerOf(tokenIds[i]) != msg.sender) continue;

            PenguinNFT(payable(penguinNFTaddress)).transferFrom(address(msg.sender), address(this), tokenIds[i]);

            UserInfo memory info;
            info.tokenId = tokenIds[i];
            info.startBlock = block.number;

            userInfo[msg.sender].push(info);
            stakingAmount[msg.sender] = stakingAmount[msg.sender] + 1;
            emit Stake(msg.sender, 1);
        }
    }

    function unstake(uint256[] memory tokenIds) public 
    {
        uint256 pending = 0;
        for(uint256 i = 0; i < tokenIds.length; i++) 
        {
            (bool _isStaked,) = getStakingItemInfo(msg.sender, tokenIds[i]);
            if(!_isStaked) continue;
            if( PenguinNFT(payable(penguinNFTaddress)).ownerOf(tokenIds[i]) != address(this) ) continue;

            uint256 temp = pendingReward(msg.sender, tokenIds[i]);
            pending = pending.add(temp);
            
            removeFromUserInfo(tokenIds[i]);
            if(stakingAmount[msg.sender] > 0)
                stakingAmount[msg.sender] = stakingAmount[msg.sender] - 1;
            PenguinNFT(payable(penguinNFTaddress)).transferFrom(address(this), msg.sender, tokenIds[i]);
            emit UnStake(msg.sender, 1);
        }

        if(pending > 0) {
            PalToken(PalTokenAddress).transfer(msg.sender, pending);
        }
    }

    function getStakingItemInfo(address _user, uint256 _tokenId) public view returns(bool _isStaked, uint256 _startBlock) 
    {
        for(uint256 i = 0; i < userInfo[_user].length; i++) 
        {
            if(userInfo[_user][i].tokenId == _tokenId) {
                _isStaked = true;
                _startBlock = userInfo[_user][i].startBlock;
                break;
            }
        }
    }

    function removeFromUserInfo(uint256 tokenId) private 
    {        
        for (uint256 i = 0; i < userInfo[msg.sender].length; i++) {
            if (userInfo[msg.sender][i].tokenId == tokenId) {
                userInfo[msg.sender][i] = userInfo[msg.sender][userInfo[msg.sender].length - 1];
                userInfo[msg.sender].pop();
                break;
            }
        }        
    }

    function claim() public 
    {
        uint256 reward = pendingTotalReward(msg.sender);

        for (uint256 i = 0; i < userInfo[msg.sender].length; i++)
            userInfo[msg.sender][i].startBlock = block.number;

        PalToken(PalTokenAddress).transfer(msg.sender, reward);
    }

}
