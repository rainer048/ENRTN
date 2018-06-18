pragma solidity 0.4.24;
import "./usingOraclize.sol";


contract ERC20Token {
  function totalSupply() public view returns(uint256);
  function balanceOf(address who) public view returns(uint256);
  function transfer(address to, uint256 value) public returns(bool);
  function transferFrom(address from, address to, uint256 value) public returns(bool);
  function approve(address spender, uint256 value) public returns(bool);
  function allowance(address who, address spender) public view returns(uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed who, address indexed spender, uint256 value);

}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
  address public pendingOwner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }
  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}



contract Crowdsale is usingOraclize, Pausable {
  using SafeMath for uint256;

  // The token being sold
  ERC20Token public token;

  // Address where funds are collected
  address public wallet;

  enum stagesOfSale {
    PRIVATE_SALE,
    PRE_SALE,
    SALE,
    NOT_SALING
  }

  stagesOfSale public stage;
  uint256 public rateInETH;
  uint256 public rate;
  uint256 public weiRaised;
  uint256 public USDinETH; // use oraclize
  uint256 public privateSaleStart;
  uint256 public privateSaleStop;
  uint256 public preSaleStart;
  uint256 public preSaleStop;
  uint256 public saleStart;
  uint256 public saleStop;
  uint256 public updatePeriod;

  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  constructor(uint256 _rateInETH, address _wallet, ERC20Token _token) public {
    require(_rateInETH > 0);
    require(_wallet != address(0));
    require(_token != address(0));
    rateInETH = _rateInETH;
    wallet = _wallet;
    token = _token;
    updatePeriod = 86400;
    USDinETH_Update();
  }

  function USDinETH_Update() public  payable {
    if (oraclize_getPrice("URL") > this.balance) {
        //newOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
    } else {
      //newOraclizeQuery("Oraclize query was sent, standing by for the answer..");
      oraclize_query(updatePeriod, "URL", "json(https://api.kraken.com/0/public/Ticker?pair=ETHUSD).result.XETHZUSD.c.0");
    }
  }

  function __callback(bytes32 myid, string result) public {
    require(msg.sender == oraclize_cbAddress());
    USDinETH = parseInt(result);
    rate = rateInETH.mul(USDinETH);
    USDinETH_Update();
  }

  function() external payable whenNotPaused() {
    buyTokens(msg.sender);
  }

  function buyTokens(address _beneficiary) public payable whenNotPaused {
    require(checkStage());
    uint256 weiAmount = msg.value;
    uint256 tokens = weiAmount.div(rate);
    tokens = getValueWithBonusPercent(tokens);
    token.transferFrom(owner, _beneficiary, tokens);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
  }

  function checkStage() public returns(bool) {
    if (now < privateSaleStart || now > privateSaleStop && now < preSaleStart || now > preSaleStop && now < saleStart || now > saleStop) {
        stage = stagesOfSale.NOT_SALING;
        return false;
    }
    else {
      if (now >= privateSaleStart && now <= privateSaleStop) {
        stage = stagesOfSale.PRIVATE_SALE;
        return true;
      }
      if (now >= preSaleStart && now <= preSaleStop) {
        stage = stagesOfSale.PRE_SALE;
        return true;
      }
      if (now >= saleStart && now <= saleStop) {
        stage = stagesOfSale.SALE;
        return true;
      }
    }
  }

  function setUpdatePeriod(uint256 _updatePeriod) public {
    require(_updatePeriod <= 86400);
    updatePeriod = _updatePeriod;
  }

  function setPrivateSaleDate(uint256 _start, uint256 _stop) public onlyOwner {
    require(_start > now);
    require(_stop > _start);
    privateSaleStart = _start;
    privateSaleStop = _stop;
  }

  function setPreSaleDate(uint256 _start, uint256 _stop) public onlyOwner {
    require(_start > now);
    require(_stop > _start);
    preSaleStart = _start;
    preSaleStop = _stop;
  }

  function setSaleDate(uint256 _start, uint256 _stop) public onlyOwner {
    require(_start > now);
    require(_stop > _start);
    saleStart = _start;
    saleStop = _stop;
  }

  function getValueWithBonusPercent(uint256 value) public view returns(uint256) {
    if (stage == stagesOfSale.NOT_SALING) return 0;
    if (stage == stagesOfSale.SALE) {
      return value;
    } else {
      uint256 cost = value.mul(rate);
      if (stage == stagesOfSale.PRIVATE_SALE) {
        if (cost > 0 && cost <= 10 * rate) {
          return value += value.mul(20).div(100);
        }
        if (cost >= 11 * rate && cost <= 30 * rate) {
          return value += value.mul(25).div(100);
        }
        if (cost >= 31 * rate) {
          return value += value.mul(30).div(100);
        }
      } else {
        if (cost > 0 && cost <= 10 * rate) {
          return value;
        }
        if (cost >= 11 * rate && cost <= 30 * rate) {
          return value += value.mul(15).div(100);
        }
        if (cost >= 31 * rate && cost <= 50 * rate) {
          return value += value.mul(20).div(100);
        }
        if (cost >= 51 * rate) {
          return value += value.mul(25).div(100);
        }
      }
    }
  }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
