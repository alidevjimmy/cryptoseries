//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Series is Ownable{
  using SafeMath for uint;

  address private _owner;
  string public title;
  uint public pledgePerEpisode;
  uint public minPublicationPeriod;
  uint public lastPublicationBlock;
  mapping(address => uint) pledges;
  address[] pledgers;
  mapping(uint => string) publishedEpisodes;
  mapping(address => uint[]) pledgesEpisodes;
  uint public totalIncome;


  event newPledger(address pledger);
  event newPledge(address indexed pledger , uint pledge , uint totalPledge );
  event withdrawal(address indexed pledger , uint pledge);
  event newPublication(string episodeLisk , uint episodeId , uint episodePay);
  event seriesClosed(uint balanceBeforeClose);
  event pldegInsufficient(address indexed pledger , uint pledge);
  event newPldegerEnrolledEpisode(address indexed pledger , uint episodeId);

  constructor (string memory _title , uint _pledgePerEpisode , uint _minPublicationPeriod) public {
    _owner = msg.sender;
    title = _title;
    pledgePerEpisode = _pledgePerEpisode;
    minPublicationPeriod = _minPublicationPeriod;
  }

  function pledge() public payable {
    require(pledges[msg.sender].add(msg.value) >= pledgePerEpisode , "Pledge must greater than pledge per episode!");
    require(msg.sender != _owner , "owner can not pledge for yourself!");

    bool oldPldeger = false;
    for (uint i = 0 ; i < pledgers.length ; i++) {
      if (msg.sender == pledgers[i]) {
        oldPldeger = true;
        break;
      }
    }
    if (!oldPldeger) {
      pledgers.push(msg.sender);
      emit newPledger(msg.sender);
    }

    pledges[msg.sender] = pledges[msg.sender].add(msg.value);
    emit newPledge(msg.sender , msg.value , pledges[msg.sender]);
  }

  function withdraw() public {
    uint amount = pledges[msg.sender];
    if (amount > 0) {
      pledges[msg.sender] = 0;
      msg.sender.transfer(amount);

      emit withdrawal(msg.sender , amount);
      emit pldegInsufficient(msg.sender , 0);
    }
  }

  function publish(string memory episodeLink) public onlyOwner(){
      require(lastPublicationBlock == 0 || block.number > lastPublicationBlock.add(minPublicationPeriod) , "owner can not publication so soon!");
      uint episodeCounter;
      lastPublicationBlock = block.number;

      episodeCounter++;
      publishedEpisodes[episodeCounter] = episodeLink;

      uint episodePays;
      for (uint i ; i < pledgers.length ; i++) {
        if (pledges[pledgers[i]] >= pledgePerEpisode) {
          pledges[pledgers[i]] = pledges[pledgers[i]].sub(pledgePerEpisode);
          episodePays = episodePays.add(pledgePerEpisode);
          pledgesEpisodes[pledgers[i]].push(episodeCounter);
          totalIncome = totalIncome.add(pledgePerEpisode);

          emit pldegInsufficient(pledgers[i] , pledges[pledgers[i]]);
          emit newPldegerEnrolledEpisode(pledgers[i] , episodeCounter);
        }
      }

      emit newPublication(episodeLink , episodeCounter , episodePays);
  }

  function buyEpisode(uint episodeId) public{
    require(pledges[msg.sender] >= pledgePerEpisode , "not enough pledges!");
    uint amount = pledges[msg.sender];
    pledges[msg.sender] = amount.sub(pledgePerEpisode);
    totalIncome = totalIncome.add(pledgePerEpisode);
    pledgesEpisodes[msg.sender].push(episodeId);

    emit pldegInsufficient(msg.sender , amount);
    emit newPldegerEnrolledEpisode(msg.sender , episodeId);
  }

  function close() public onlyOwner(){
    for (uint i = 0 ; i < pledgers.length ; i++) {
      uint amount = pledges[pledgers[i]];
      if (amount > 0) {
       payable(pledgers[i]).transfer(amount);
      }
    }
    emit seriesClosed(address(this).balance);
    selfdestruct(payable(_owner));
  }

  function totalPledgers() public view returns(uint) {
    return pledgers.length;
  }

  function activePledgers() public view returns(uint) {
    uint actives;
    for (uint i = 0 ; i < pledgers.length ; i++) {
      if (pledges[pledgers[i]] >= pledgePerEpisode) {
        actives++;
      }
    }

    return actives;
  }

  function totalPays() public view returns(uint) {
    return totalIncome;
  }
}
