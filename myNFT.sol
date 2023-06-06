//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "https://github.com/klaytn/klaytn-contracts/blob/master/contracts/KIP/token/KIP17/extensions/KIP17Enumerable.sol";
import "https://github.com/klaytn/klaytn-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";
/*
D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One 
D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One
D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One
                                                        
                                                         JUST_MINT_NFTS

                                                       Programmed by D_One                                                                    
                                               FEEL FREE TO USE THIS SMART CONTRAC ;)                                            
                                          IF YOU FOUND BUGS HERE, PLEASE LET ME KNOW THAT           

D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One 
D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One
D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One D_One
*/

/*
특징
1. NFT 대량 민트
2. 프론트엔드 없이 NFT 판매

Ex) 발행한 스마트 컨트랙트 주소 : 0xF3f8391733431370520a74EC8A1Ab8D7CD9fC744
    1. A가 0xF3f8391733431370520a74EC8A1Ab8D7CD9fC744(발행한 스마트 컨트랙트 주소)에게 0.01 klay를 준다.
    2. 0xF3f8391733431370520a74EC8A1Ab8D7CD9fC744 A에게 NFT를 발행한다.
    3. A는 15블록이후로 민트 가능하다. 
    4. 배포자는 witdraw 함수로 판매된 NFT의 이더를 갖고 올 수 있다

NFT 발행 순서

1._baseURI함수에서 메타데이터(metadata) CID 추가
2. 컴파일 (ctrl+s)
3. DEPLOY & RUN TRANSACTIONS : ACCOUNT -> private key 입력
4. CONTRACT -> myNFT 선택
5. myNFT의 아규먼트(argument) 넣어주기

    -_NAME : 토큰 이름 D_One'test_NFT_Klaytn
    -_SYMBOL : 토큰 심볼 D_One'test_NFT_Klaytn
    -_LIMIT : NFT 최대 발행 개수 10  
    EX)
    첫번째 발행된 NFT의 id : 1 -> 메타데이터 1.json -> 그림 1.png
    두번째 발행된 NFT의 id : 2 -> 메타데이터 2.json -> 그림 2.png
        ...
    열번째 발행된 NFT의 id : 10 -> 메타데이터 10.json -> 그림 10.png     
    limit = 10 
    열한번째 발행된 NFT의 id : 11 -> 메타데이터 11.json -> 그림 11.png   -> X  

    -_PRICE : NFT 판매 가격  10000000000000000
    100 klay = 10^20 10 klay = 10^19
    1Klay = 10^18 / 0.1 Klay = 10^17 / 0.01 Klay = 10^16

    -_INTERVAL : NFT 민트 간격 (봇이 독점 방지) 15
        EX) 현재 블록 : 100 
            간격 : 15 블록
            A -> 100번째 블록에서 NFT 민트(mint) -> 101~114 블록 민트 불가 ->115블록 부터 다시 NFT 민트(mint) 가능
            B -> 105번째 블록에서 NFT 민트(mint)
            (클레이튼 초당 1블록)

    -_REAVELINGBLOCK : 언제 NFT가 공개되는지 15
        EX) 현재 블록 : 100 
            공개 시작 블록 : 15블록 
            cvoer.js 파일에 있는 그림(NFT공개전 그림) -> 115 블록 -> 진짜 NFT 그림

    -_NOTREVELEDNFTURI : 진짜 NFT를 공개 하기전의 그림의 메타데이터 즉 Cover.js URI 
        EX)  ipfs://QmXr2ENd5KuxqQHpMGqJnYhTtTVraHAo11MFdDd6fucaHV를 에서 YOUR_CID를 Cover.js의 CID로 변경하기.
   
6. Deploy 또는 transact 버튼 누르기

*/

contract myNFT is KIP17Enumerable, Ownable, ReentrancyGuard  {

    
    error WaitForACoupleOfBlocks(uint tillBlock, uint currentBlock);
    error InsufficientValue(uint paidPrice, uint price);
    error OutOfNfts();
    error FailedToWithdraw();

    uint public limit;
    uint public latestId;
    uint public price;
    uint public interval;
    uint public revelingBlock;
    string public notReveledNFTURI; 
    mapping(address=>uint) public NumberTracker; 

    using Strings for uint; 

    constructor(
        string memory _name, 
        string memory _symbol, 
        uint _limit, 
        uint _price, 
        uint _interval,
        uint _revelingBlock,
        string memory _notReveledNFTURI
    ) KIP17(_name, _symbol) 
    {   
        limit = _limit;
        price = _price;
        interval = _interval;
        revelingBlock = _revelingBlock + block.number;
        notReveledNFTURI = _notReveledNFTURI;
    }

    receive() external payable{
       mint();
    }

    function mint() public payable nonReentrant() {
        if(NumberTracker[msg.sender] == 0 ? false : NumberTracker[msg.sender] + interval >= block.number) {
            revert WaitForACoupleOfBlocks(NumberTracker[msg.sender] + interval,block.number);
        }
        if(price != msg.value) {
            revert InsufficientValue(msg.value, price);
        }
        if(latestId >= limit) {
            revert OutOfNfts();
        }
        _safeMint(msg.sender, ++latestId);
        NumberTracker[msg.sender] = block.number;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "KIP17Metadata: URI query for nonexistent token");

        if(revelingBlock<=block.number){
            string memory baseURI = _baseURI();
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : "";
        }else{
            return notReveledNFTURI;
        }

       
    }

    /// Your_CID를 metadata CID로 변경해야 함
    /// ipfs://____ / 뒤에 슬래쉬 꼭 필요!!!
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmWqc4ezRh7piXJZ1UmUzgmCTP1DWzc7vy3p7Y8d33fYig/";
    }

   /// 리믹스 상에서 한번에 약 최대 250개 정도 가능  
   /// 원하는 유저에게 NFT를 줄 수 있음 (to : NFT를 받는 주소, _number : 몇개의 NFT를 줄것인지)
    function u_airdrop( address _to, uint _number) external onlyOwner() {
        if(latestId + _number > limit){
            revert OutOfNfts();
        }

        for(uint i; i < _number; ++i){
            _safeMint(_to, ++latestId);
        }
    }

    /// 리믹스 상에서 한번에 약 최대 250개 정도 가능  
    /// ["유저주소", "유저주소2" ] 각 유저에게 한개씩 에어드랍.
    /// ex) ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2"]
    function u_airdrop2(address[] calldata _to) external onlyOwner() {
        uint _size = _to.length;
        if(latestId + _size > limit){
            revert OutOfNfts();
        }
        for(uint i; i < _size; ++i){
          _safeMint(_to[i], ++latestId);
        }
    }


    /// NFT 판매 가격 변경하는 함수
    function u_setPrice(uint _price) external onlyOwner()  {
        price = _price;
    } 

    /// NFT 민트할 수 있는 간격 정하는 함수
    function u_setInterval(uint _interval) external onlyOwner(){
        interval = _interval;
    } 

    /// NFT 실제 그림 몇 번째 블록에서 공개하는지 정하는 함수   
    function u_setRevelingBlock(uint _revelingBlock) external onlyOwner(){
        revelingBlock = _revelingBlock + block.number;
    } 
     
    /// 얼마후 NFT 실제 그림 공개하는지 보여주는 함수
    function u_whenToRevelNFTs() external view returns(uint) {
       return revelingBlock <= block.number  ? 0 : revelingBlock - block.number ;
    } 
   
    /// 현재 NFT 판매금액
    function u_currentBalance() external view returns(uint) {
      return address(this).balance;
    }
    
    /// 판매금액 출금하기
    function u_withdraw() external onlyOwner() {
      (bool _result,) = address(msg.sender).call{value:address(this).balance}("");
      if(!_result) revert FailedToWithdraw();
    }


}
