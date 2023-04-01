const { expect } = require("chai");
const hre = require("hardhat");
const { BigNumber, getSigners } = hre.ethers;
const { ZERO_ADDRESS, DAY_IN_SECONDS } = require("./consts");

describe("CHRPresale", function () {
  //setup values
  const stageAmount = ["40000000", "80000000", "160000000", "200000000"].map(BigNumber.from);
  const stagePrice = ["12000", "14000", "16000", "18000"].map(BigNumber.from);

  async function deployCHRTokenFixture(creator) {
    const CHRFactory = await hre.ethers.getContractFactory("CHRToken");
    return await CHRFactory.connect(creator).deploy(250000000, 500000000);
  }

  async function deployUSDTStubFixture(creator) {
    const USDTFactory = await hre.ethers.getContractFactory("USDTMock");
    return await USDTFactory.connect(creator).deploy("50000000000000000", "Tether USD", "USDT", 6);
  }

  async function deployChainlinkPriceFeedStubFixture(creator) {
    const ChainlinkPriceFeedFactory = await hre.ethers.getContractFactory("MockAggregator");
    return await ChainlinkPriceFeedFactory.connect(creator).deploy();
  }

  it("should be correctly deployed", async function () {
    //setup values
    const saleStartTime = Math.floor(new Date().getTime() / 1000) + DAY_IN_SECONDS;
    const saleEndTime = Math.floor(new Date().getTime() / 1000) + DAY_IN_SECONDS * 2;

    const [creator] = await getSigners();

    //Deploy necessary contracts
    const CHR = await deployCHRTokenFixture(creator);
    const USDT = await deployUSDTStubFixture(creator);
    const ChainlinkPriceFeed = await deployChainlinkPriceFeedStubFixture(creator);

    //Deploy contract
    const presaleFactory = await hre.ethers.getContractFactory("CHRPresale");
    const presale = presaleFactory
      .connect(creator)
      .deploy(
        CHR.address,
        ChainlinkPriceFeed.address,
        USDT.address,
        saleStartTime,
        saleEndTime,
        stageAmount,
        stagePrice
      );

    //Assert deploy was successful
    await expect(presale).not.to.be.reverted;
    expect((await presale).address).not.equal(ZERO_ADDRESS);
  });

  it("should be reverted if oracle address is zero address", async function () {
    //setup values
    const saleStartTime = Math.floor(new Date().getTime() / 1000) + DAY_IN_SECONDS;
    const saleEndTime = Math.floor(new Date().getTime() / 1000) + DAY_IN_SECONDS * 2;

    const [creator] = await getSigners();

    //Deploy necessary contracts
    const CHR = await deployCHRTokenFixture(creator);
    const USDT = await deployUSDTStubFixture(creator);

    //Deploy contract
    const presaleFactory = await hre.ethers.getContractFactory("CHRPresale");
    const presale = presaleFactory
      .connect(creator)
      .deploy(CHR.address, ZERO_ADDRESS, USDT.address, saleStartTime, saleEndTime, stageAmount, stagePrice);

    //Assert was reverted
    await expect(presale).to.be.reverted;
  });

  it("should be reverted if USDT address is zero address", async function () {
    //setup values
    const saleStartTime = Math.floor(new Date().getTime() / 1000) + DAY_IN_SECONDS;
    const saleEndTime = Math.floor(new Date().getTime() / 1000) + DAY_IN_SECONDS * 2;

    const [creator] = await getSigners();

    //Deploy necessary contracts
    const CHR = await deployCHRTokenFixture(creator);
    const ChainlinkPriceFeed = await deployChainlinkPriceFeedStubFixture(creator);

    //Deploy contract
    const presaleFactory = await hre.ethers.getContractFactory("CHRPresale");
    const presale = presaleFactory
      .connect(creator)
      .deploy(
        CHR.address,
        ChainlinkPriceFeed.address,
        ZERO_ADDRESS,
        saleStartTime,
        saleEndTime,
        stageAmount,
        stagePrice
      );

    //Assert was reverted
    await expect(presale).to.be.reverted;
  });

  it("should be reverted if sale token address is zero address", async function () {
    //setup values
    const saleStartTime = Math.floor(new Date().getTime() / 1000) + DAY_IN_SECONDS;
    const saleEndTime = Math.floor(new Date().getTime() / 1000) + DAY_IN_SECONDS * 2;

    const [creator] = await getSigners();

    //Deploy necessary contracts
    const USDT = await deployUSDTStubFixture(creator);
    const ChainlinkPriceFeed = await deployChainlinkPriceFeedStubFixture(creator);

    //Deploy contract
    const presaleFactory = await hre.ethers.getContractFactory("CHRPresale");
    const presale = presaleFactory
      .connect(creator)
      .deploy(
        ZERO_ADDRESS,
        ChainlinkPriceFeed.address,
        USDT.address,
        saleStartTime,
        saleEndTime,
        stageAmount,
        stagePrice
      );

    //Assert was reverted
    await expect(presale).to.be.reverted;
  });

  it("should emit SaleTimeUpdated", async function () {
    //setup values
    const saleStartTime = Math.floor(new Date().getTime() / 1000) + DAY_IN_SECONDS;
    const saleEndTime = Math.floor(new Date().getTime() / 1000) + DAY_IN_SECONDS * 2;

    const [creator] = await getSigners();

    //Deploy necessary contracts
    const CHR = await deployCHRTokenFixture(creator);
    const USDT = await deployUSDTStubFixture(creator);
    const ChainlinkPriceFeed = await deployChainlinkPriceFeedStubFixture(creator);

    //Deploy contract
    const presaleFactory = await hre.ethers.getContractFactory("CHRPresale");
    const presale = presaleFactory
      .connect(creator)
      .deploy(
        CHR.address,
        ChainlinkPriceFeed.address,
        USDT.address,
        saleStartTime,
        saleEndTime,
        stageAmount,
        stagePrice
      );

    //Assert deploy was successful
    await expect(presale).not.to.be.reverted;
    expect((await presale).address).not.equal(ZERO_ADDRESS);

    //Assert SaleStartTimeUpdated event was emitted
    expect(presale)
      .to.emit(await presale, "SaleTimeUpdated")
      .withArgs(saleStartTime, saleEndTime)
  });

  it("should have correct values after deploy", async function () {
    //setup values
    const saleStartTime = Math.floor(new Date().getTime() / 1000) + DAY_IN_SECONDS;
    const saleEndTime = Math.floor(new Date().getTime() / 1000) + DAY_IN_SECONDS * 2;

    const [creator] = await getSigners();

    //Deploy necessary contracts
    const CHR = await deployCHRTokenFixture(creator);
    const USDT = await deployUSDTStubFixture(creator);
    const ChainlinkPriceFeed = await deployChainlinkPriceFeedStubFixture(creator);

    //Deploy contract
    const presaleFactory = await hre.ethers.getContractFactory("CHRPresale");
    const presaleTx = presaleFactory
      .connect(creator)
      .deploy(
        CHR.address,
        ChainlinkPriceFeed.address,
        USDT.address,
        saleStartTime,
        saleEndTime,
        stageAmount,
        stagePrice
      );

    //Assert deploy was successful
    await expect(presaleTx).not.to.be.reverted;
    expect((await presaleTx).address).not.equal(ZERO_ADDRESS);

    const presale = await presaleTx;

    //Get contract values
    const presaleTotalTokensSold = await presale.totalTokensSold();
    const presaleClaimStartTime = await presale.claimStartTime();
    const presaleSaleStartTime = await presale.saleStartTime();
    const presaleSaleEndTime = await presale.saleEndTime();
    const presaleCurrentStage = await presale.currentStage();
    const presaleUSDTToken = await presale.usdtToken();
    const presaleOracle = await presale.oracle();

    //Assert deploy was successful
    await expect(presale).not.to.be.reverted;
    expect((await presale).address).not.equal(ZERO_ADDRESS);

    //Assert contract values are equal to expected
    expect(presaleTotalTokensSold).to.equal(0);
    expect(presaleClaimStartTime).to.equal(0);
    expect(presaleSaleStartTime).to.equal(saleStartTime);
    expect(presaleSaleEndTime).to.equal(saleEndTime);
    expect(presaleCurrentStage).to.equal(0);
    expect(presaleUSDTToken).to.equal(USDT.address);
    expect(presaleOracle).to.equal(ChainlinkPriceFeed.address);
  });

  describe("Presale functions", function () {
    async function deployPresaleFixture() {
      //setup values
      const block = await hre.ethers.provider.getBlock("latest");
      const saleStartTime = block.timestamp + DAY_IN_SECONDS;
      const saleEndTime = saleStartTime + DAY_IN_SECONDS;

      const [creator, presaleOwner, Alice] = await getSigners();

      //Deploy necessary contracts
      const CHR = await deployCHRTokenFixture(creator);
      const USDT = await deployUSDTStubFixture(creator);
      const ChainlinkPriceFeed = await deployChainlinkPriceFeedStubFixture(creator);

      //Deploy presale contract
      const presaleFactory = await hre.ethers.getContractFactory("CHRPresale");
      const presale = await presaleFactory
        .connect(creator)
        .deploy(
          CHR.address,
          ChainlinkPriceFeed.address,
          USDT.address,
          saleStartTime,
          saleEndTime,
          stageAmount,
          stagePrice
        );

      //Transfer presale contract ownership to specified address
      await presale.transferOwnership(presaleOwner.address);

      return {
        USDT,
        CHR,
        ChainlinkPriceFeed,
        presale,
        saleStartTime,
        saleEndTime,
        stageAmount,
        stagePrice,
        users: {
          creator,
          presaleOwner,
          Alice,
        },
      };
    }

    async function purchaseTokensFixture(contract, signer, amount) {
      const priceInWei = await contract.connect(signer).getPriceInETH(amount);
      await contract.connect(signer).buyWithEth(amount, { value: priceInWei });
    }

    async function timeTravelFixture(targetTime) {
      await hre.network.provider.send("evm_setNextBlockTimestamp", [targetTime]);
    }

    async function startClaimFixture(presale, CHR, creator, presaleOwner, claimStartTime, tokensAmount) {
      const valueToTransfer = BigNumber.from(tokensAmount).mul(BigNumber.from(10).pow(await CHR.decimals()));
      await CHR.connect(creator).transfer(presale.address, valueToTransfer);
      await presale.connect(presaleOwner).configureClaim(claimStartTime);
    }

    describe("'pause' function", function () {
      it("should pause contract if called by the owner", async function () {
        //Set values
        const { presale, users } = await deployPresaleFixture();

        //Get paused status before transaction
        const pauseStatusBefore = await presale.paused();

        //Pause contract
        const pauseTx = presale.connect(users.presaleOwner).pause();

        //Assert transaction was successful
        await expect(pauseTx).not.to.be.reverted;

        //Get paused status after transaction
        const pauseStatusAfter = await presale.paused();

        //Assert transaction results
        expect(pauseStatusBefore).to.equal(false);
        expect(pauseStatusAfter).to.equal(true);
      });

      it("should revert if called not by the owner", async function () {
        //Set values
        const { presale } = await deployPresaleFixture();

        //Pause contract
        const pauseTx = presale.pause();

        //Assert transaction is reverted
        await expect(pauseTx).to.be.revertedWith("Ownable: caller is not the owner");
      });

      it("should revert if contract already paused", async function () {
        //Set values
        const { presale, users } = await deployPresaleFixture();

        //Preliminarily pause contract
        await presale.connect(users.presaleOwner).pause();

        //Pause contract
        const pauseTx = presale.connect(users.presaleOwner).pause();

        //Assert transaction is reverted
        await expect(pauseTx).to.be.revertedWith("Pausable: paused");
      });
    });

    describe("'unpause' function", function () {
      it("should unpause contract if called by the owner", async function () {
        //Set values
        const { presale, users } = await deployPresaleFixture();

        //Preliminarily pause contract
        await presale.connect(users.presaleOwner).pause();

        //Get paused status before transaction
        const pauseStatusBefore = await presale.paused();

        //Unpause contract
        const pauseTx = presale.connect(users.presaleOwner).unpause();

        //Assert transaction was successful
        await expect(pauseTx).not.to.be.reverted;

        //Get paused status after transaction
        const pauseStatusAfter = await presale.paused();

        //Assert transaction results
        expect(pauseStatusBefore).to.equal(true);
        expect(pauseStatusAfter).to.equal(false);
      });

      it("should revert if called not by the owner", async function () {
        //Set values
        const { presale } = await deployPresaleFixture();

        //Pause contract
        const pauseTx = presale.unpause();

        //Assert transaction is reverted
        await expect(pauseTx).to.be.revertedWith("Ownable: caller is not the owner");
      });

      it("should revert if contract already unpaused", async function () {
        //Set values
        const { presale, users } = await deployPresaleFixture();

        //Unpause contract
        const unpauseTx = presale.connect(users.presaleOwner).unpause();

        //Assert transaction is reverted
        await expect(unpauseTx).to.be.revertedWith("Pausable: not paused");
      });
    });

    describe("'configureSaleTimeframe' function", function () {
      it("should set sales start time", async function () {
        //Set values
        const { presale, users } = await deployPresaleFixture();

        const saleTimeModifier = DAY_IN_SECONDS;

        //Get sale start time before transaction
        const saleStartTimeBefore = await presale.saleStartTime();
        const saleEndTimeBefore = await presale.saleEndTime();

        //Change sale start time
        const changeSaleStartTimeTx = presale
          .connect(users.presaleOwner)
          .configureSaleTimeframe(
            saleStartTimeBefore.add(saleTimeModifier),
            saleEndTimeBefore.add(saleTimeModifier)
          );

        //Assert transaction was successful
        await expect(changeSaleStartTimeTx).not.to.be.reverted;

        //Get sales start time after transaction
        const saleStartTimeAfter = await presale.saleStartTime();
        const saleEndTimeAfter = await presale.saleEndTime();

        //Assert sale start time after transaction with expected
        expect(saleStartTimeAfter).to.equal(saleStartTimeBefore.add(saleTimeModifier));
        expect(saleEndTimeAfter).to.equal(saleEndTimeBefore.add(saleTimeModifier));
      });

      it("should revert if called not by the owner", async function () {
        //Set values
        const { presale } = await deployPresaleFixture();

        //Change sale start time
        const changeSaleStartTimeTx = presale.configureSaleTimeframe(0, 0);

        //Assert transaction is reverted
        await expect(changeSaleStartTimeTx).to.be.revertedWith("Ownable: caller is not the owner");
      });

      it("should emit SaleTimeUpdated event", async function () {
        //Set values
        const { presale, users } = await deployPresaleFixture();

        const saleTimeModifier = DAY_IN_SECONDS;

        //Get sale start time before transaction
        const saleStartTimeBefore = await presale.saleStartTime();
        const saleEndTimeBefore = await presale.saleEndTime();

        //Change sale start time
        const changeSaleStartTimeTx = presale
          .connect(users.presaleOwner)
          .configureSaleTimeframe(
            saleStartTimeBefore.add(saleTimeModifier),
            saleEndTimeBefore.add(saleTimeModifier).add(saleTimeModifier)
          );

        //Assert transaction was successful
        await expect(changeSaleStartTimeTx).not.to.be.reverted;

        //Assert SaleStartTimeUpdated event was emitted
        expect(changeSaleStartTimeTx)
          .to.emit(presale, "SaleTimeUpdated")
          .withArgs(saleStartTimeBefore.add(saleTimeModifier), saleEndTimeBefore.add(saleTimeModifier));
      });
    });

    describe("'configureClaim' function", function () {
      it("should set claim start time", async function () {
        //Set values
        const { presale, users, saleEndTime, CHR } = await deployPresaleFixture();
        const tokensAmount = 100;

        //Get claim start time before transaction
        const claimStartTimeBefore = await presale.claimStartTime();

        //Transfer tokens to presale contract
        await CHR.connect(users.creator).transfer(
          presale.address,
          BigNumber.from(tokensAmount).mul(BigNumber.from(10).pow(await CHR.decimals()))
        );

        //Start claim
        const configureClaimTx = presale
          .connect(users.presaleOwner)
          .configureClaim(saleEndTime + DAY_IN_SECONDS);

        //Assert transaction was successful
        await expect(configureClaimTx).not.to.be.reverted;

        //Get sales start time after transaction
        const claimStartTimeAfter = await presale.claimStartTime();

        //Assert claim start time after transaction with expected
        expect(claimStartTimeBefore).to.equal(0);
        expect(claimStartTimeAfter).to.equal(saleEndTime + DAY_IN_SECONDS);
      });

      it("should revert if called not by the owner", async function () {
        //Set values
        const { presale, users, CHR } = await deployPresaleFixture();
        const tokensAmount = 100;

        //Transfer tokens to presale contract
        await CHR.connect(users.creator).transfer(presale.address, tokensAmount);

        //Change claim start time
        const configureClaimTx = presale.configureClaim(0);

        //Assert transaction is reverted
        await expect(configureClaimTx).to.be.revertedWith("Ownable: caller is not the owner");
      });

      it("should emit SaleStartTimeUpdated event", async function () {
        //Set values
        const { presale, users, saleEndTime, CHR } = await deployPresaleFixture();
        const tokensAmount = 100;

        const claimStartTimeModifier = DAY_IN_SECONDS;

        //Get claim start time before transaction
        const claimStartTimeBefore = await presale.claimStartTime();

        //Transfer tokens to presale contract
        await CHR.connect(users.creator).transfer(
          presale.address,
          BigNumber.from(tokensAmount).mul(BigNumber.from(10).pow(await CHR.decimals()))
        );

        //Claim start time
        const claimStartTimeTx = presale
          .connect(users.presaleOwner)
          .configureClaim(saleEndTime + DAY_IN_SECONDS);

        //Assert transaction was successful
        await expect(claimStartTimeTx).not.to.be.reverted;

        //Assert SaleEndTimeUpdated event was emitted
        expect(claimStartTimeTx)
          .to.emit(presale, "ClaimStartTimeUpdated")
          .withArgs(claimStartTimeBefore.add(claimStartTimeModifier));
      });

      it("should revert if balance less than sold amount", async function () {
        //Set values
        const { presale, users, saleEndTime, saleStartTime, CHR } = await deployPresaleFixture();
        const tokensAmount = 100;

        //Transfer tokens to presale contract
        await CHR.connect(users.creator).transfer(presale.address, tokensAmount);

        //Time travel to sales period
        await timeTravelFixture(saleStartTime + 1);

        //Purchase some tokens
        await purchaseTokensFixture(presale, users.creator, tokensAmount);

        //Start claim
        const configureClaimTx = presale
          .connect(users.presaleOwner)
          .configureClaim(saleEndTime + DAY_IN_SECONDS);

        //Assert transaction was reverted
        await expect(configureClaimTx).to.be.revertedWith("Not enough balance");
      });
    });

    describe("'getCurrentPrice' function", function () {
      it("should return stage price for current stage", async function () {
        //Set values
        const { presale, stagePrice } = await deployPresaleFixture();

        //Get current stage
        const stage = await presale.currentStage();

        //Get current stage price
        const getCurrentPriceTx = presale.getCurrentPrice();

        //Assert transaction was successful
        await expect(getCurrentPriceTx).not.to.be.reverted;

        //Assert current stage price with expected
        expect(await getCurrentPriceTx).to.equal(stagePrice[stage]);
      });
    });

    describe("'getTotalPresaleAmount' function", function () {
      it("should return total presale limit", async function () {
        //Set values
        const { presale, stageAmount } = await deployPresaleFixture();

        //Get total presale amount
        const getTotalPresaleAmountTx = presale.getTotalPresaleAmount();

        //Assert transaction was successful
        await expect(getTotalPresaleAmountTx).not.to.be.reverted;

        //Assert total presale amount with expected
        expect(await getTotalPresaleAmountTx).to.equal(stageAmount[stageAmount.length - 1]);
      });
    });

    describe("'totalSoldPrice' function", function () {
      it("should return total cost of sold tokens", async function () {
        //Set values
        const { presale, users, saleStartTime, stagePrice, stageAmount } = await deployPresaleFixture();
        const tokensToPurchase = 1000;

        //Timeshift to sale period
        await timeTravelFixture(saleStartTime + 1);

        //Purchase some tokens
        await purchaseTokensFixture(presale, users.creator, tokensToPurchase);

        //Get total token sold amount
        const tokensSold = await presale.totalTokensSold();

        //Calculate expected price
        let price = BigNumber.from(0);
        let tokensCalculated = 0;
        for (let i = 0; tokensSold <= stageAmount[i]; i++) {
          const tokensForStage = Math.min(tokensSold, stageAmount[i]) - tokensCalculated;
          price = price.add(stagePrice[i].mul(tokensForStage));
          tokensCalculated += tokensForStage;
        }

        //Get total sold price
        const totalSoldPriceTx = presale.totalSoldPrice();

        //Assert transaction was successful
        await expect(totalSoldPriceTx).not.to.be.reverted;

        //Assert total sold price with expected
        expect(await totalSoldPriceTx).to.equal(price);
      });
    });

    describe("'buyWithEth' function", function () {
      it("should increase purchased tokens amount and transfer payment to owner", async function () {
        //Set values
        const { presale, users, saleStartTime, CHR } = await deployPresaleFixture();
        const tokensToPurchase = 1000;

        //Timeshift to sale period
        await timeTravelFixture(saleStartTime + 1);

        //Get wei price
        const weiPrice = await presale.getPriceInETH(tokensToPurchase);

        //Get values before transaction
        const purchaseTokensAmountBefore = await presale.purchasedTokens(users.creator.address);
        const ETHAmountBefore = await hre.ethers.provider.getBalance(users.presaleOwner.address);

        //Buy with eth
        const buyWithEthTx = presale.connect(users.creator).buyWithEth(tokensToPurchase, { value: weiPrice });

        //Assert transaction was successful
        await expect(buyWithEthTx).not.to.be.reverted;

        //Get values after transaction
        const purchaseTokensAmountAfter = await presale.purchasedTokens(users.creator.address);
        const ETHAmountAfter = await hre.ethers.provider.getBalance(users.presaleOwner.address);
        const decimals = await CHR.decimals();

        //Assert values with expected
        expect(purchaseTokensAmountAfter).to.equal(
          purchaseTokensAmountBefore.add(BigNumber.from(10).pow(decimals).mul(tokensToPurchase))
        );
        expect(ETHAmountAfter).to.equal(ETHAmountBefore.add(weiPrice));
      });

      it("should revert if trying to buy before sales start", async function () {
        //Set values
        const { presale, users } = await deployPresaleFixture();
        const tokensToPurchase = 1000;

        //Get wei price
        const weiPrice = await presale.getPriceInETH(tokensToPurchase);

        //Buy with eth
        const buyWithEthTx = presale.connect(users.creator).buyWithEth(tokensToPurchase, { value: weiPrice });

        //Assert transaction was reverted
        await expect(buyWithEthTx).to.be.revertedWithCustomError(presale, "InvalidTimeframe");
      });

      it("should revert if not enough value", async function () {
        //Set values
        const { presale, users, saleStartTime } = await deployPresaleFixture();
        const tokensToPurchase = 1000;

        //Timeshift to sale period
        await timeTravelFixture(saleStartTime + 1);

        //Get wei price
        const weiPrice = await presale.getPriceInETH(tokensToPurchase);

        //Buy with eth
        const buyWithEthTx = presale
          .connect(users.creator)
          .buyWithEth(tokensToPurchase, { value: weiPrice.sub(1) });

        //Assert transaction was reverted
        await expect(buyWithEthTx).to.be.revertedWithCustomError(presale, "NotEnoughETH");
      });

      it("should revert if try to buy more tokens than presale limit", async function () {
        //Set values
        const { presale, users, saleStartTime, stageAmount } = await deployPresaleFixture();
        const tokensToPurchase = stageAmount[stageAmount.length - 1];

        //Timeshift to sale period
        await timeTravelFixture(saleStartTime + 1);

        //Get wei price
        const weiPrice = await presale.getPriceInETH(tokensToPurchase);

        //Buy with eth
        const buyWithEthTx = presale
          .connect(users.creator)
          .buyWithEth(tokensToPurchase + 1, { value: weiPrice });

        //Assert transaction was reverted
        await expect(buyWithEthTx).to.be.revertedWithCustomError(presale, "PresaleLimitExceeded");
      });

      it("should revert if try to buy 0 tokens", async function () {
        //Set values
        const { presale, users, saleStartTime } = await deployPresaleFixture();
        const tokensToPurchase = 0;

        //Timeshift to sale period
        await timeTravelFixture(saleStartTime + 1);

        //Get wei price
        const weiPrice = await presale.getPriceInETH(tokensToPurchase);

        //Buy with eth
        const buyWithEthTx = presale.connect(users.creator).buyWithEth(tokensToPurchase, { value: weiPrice });

        //Assert transaction was reverted
        await expect(buyWithEthTx).to.be.revertedWithCustomError(presale, "BuyAtLeastOneToken");
      });

      it("should emit TokensBought event", async function () {
        //Set values
        const { presale, users, saleStartTime } = await deployPresaleFixture();
        const tokensToPurchase = 1000;

        //Timeshift to sale period
        await timeTravelFixture(saleStartTime + 1);

        //Get wei price
        const weiPrice = await presale.getPriceInETH(tokensToPurchase);
        const USDTPrice = await presale.getPriceInUSDT(tokensToPurchase);

        //Buy with eth
        const buyWithEthTx = presale.connect(users.creator).buyWithEth(tokensToPurchase, { value: weiPrice });

        //Assert transaction was successful
        await expect(buyWithEthTx).not.to.be.reverted;

        //Assert TokensBought event was emitted
        expect(await buyWithEthTx)
          .to.emit(presale, "TokensBought")
          .withArgs(users.creator.address, "ETH", tokensToPurchase, USDTPrice, weiPrice);
      });
    });

    describe("'buyWithUSDT' function", function () {
      it("should increase purchased tokens amount and transfer payment to owner", async function () {
        //Set values
        const { presale, users, saleStartTime, CHR, USDT } = await deployPresaleFixture();
        const tokensToPurchase = 1000;

        //Timeshift to sale period
        await timeTravelFixture(saleStartTime + 1);

        //Get usdt price
        const USDTPrice = await presale.getPriceInUSDT(tokensToPurchase);

        //Add allowance to contract
        await USDT.connect(users.creator).approve(presale.address, USDTPrice);

        //Get values before transaction
        const purchaseTokensAmountBefore = await presale.purchasedTokens(users.creator.address);
        const USDTAmountBefore = await USDT.balanceOf(users.presaleOwner.address);

        //Buy with USDT
        const buyWithUSDTTx = presale.connect(users.creator).buyWithUSDT(tokensToPurchase);

        //Assert transaction was successful
        await expect(buyWithUSDTTx).not.to.be.reverted;

        //Get values after transaction
        const purchaseTokensAmountAfter = await presale.purchasedTokens(users.creator.address);
        const USDTAmountAfter = await USDT.balanceOf(users.presaleOwner.address);
        const decimals = await CHR.decimals();

        //Assert total sold price with expected
        expect(purchaseTokensAmountAfter).to.equal(
          purchaseTokensAmountBefore.add(BigNumber.from(10).pow(decimals).mul(tokensToPurchase))
        );
        expect(USDTAmountAfter).to.equal(USDTAmountBefore.add(USDTPrice));
      });

      it("should revert if trying to buy before sales start", async function () {
        //Set values
        const { presale, users, USDT } = await deployPresaleFixture();
        const tokensToPurchase = 1000;

        //Get usdt price
        const USDTPrice = await presale.getPriceInUSDT(tokensToPurchase);

        //Add allowance to contract
        await USDT.connect(users.creator).approve(presale.address, USDTPrice);

        //Buy with USDT
        const buyWithUSDTTx = presale.connect(users.creator).buyWithUSDT(tokensToPurchase);

        //Assert transaction was reverted
        await expect(buyWithUSDTTx).to.be.revertedWithCustomError(presale, "InvalidTimeframe");
      });

      it("should revert if not enough allowance", async function () {
        //Set values
        const { presale, users, saleStartTime } = await deployPresaleFixture();
        const tokensToPurchase = 1000;

        //Timeshift to sale period
        await timeTravelFixture(saleStartTime + 1);

        //Buy with USDT
        const buyWithUSDTTx = presale.connect(users.creator).buyWithUSDT(tokensToPurchase);

        //Assert transaction was reverted
        await expect(buyWithUSDTTx).to.be.revertedWithCustomError(presale, "NotEnoughAllowance");
      });

      it("should revert if try to buy more tokens than presale limit", async function () {
        //Set values
        const { presale, users, saleStartTime, stageAmount, USDT } = await deployPresaleFixture();
        const tokensToPurchase = stageAmount[stageAmount.length - 1];

        //Timeshift to sale period
        await timeTravelFixture(saleStartTime + 1);

        //Get usdt price
        const USDTPrice = await presale.getPriceInUSDT(tokensToPurchase);

        //Add allowance to contract
        await USDT.connect(users.creator).approve(presale.address, USDTPrice);

        //Buy with USDT
        const buyWithUSDTTx = presale.connect(users.creator).buyWithUSDT(tokensToPurchase);

        //Assert transaction was reverted
        await expect(buyWithUSDTTx).to.be.revertedWith("Insufficient funds");
      });

      it("should revert if try to buy 0 tokens", async function () {
        //Set values
        const { presale, users, saleStartTime, USDT } = await deployPresaleFixture();
        const tokensToPurchase = 0;

        //Timeshift to sale period
        await timeTravelFixture(saleStartTime + 1);

        //Get usdt price
        const USDTPrice = await presale.getPriceInUSDT(tokensToPurchase);

        //Add allowance to contract
        await USDT.connect(users.creator).approve(presale.address, USDTPrice);

        //Buy with USDT
        const buyWithUSDTTx = presale.connect(users.creator).buyWithUSDT(tokensToPurchase);

        //Assert transaction was reverted
        await expect(buyWithUSDTTx).to.be.revertedWithCustomError(presale, "BuyAtLeastOneToken");
      });

      it("should emit TokensBought event", async function () {
        //Set values
        const { presale, users, saleStartTime, USDT } = await deployPresaleFixture();
        const tokensToPurchase = 1000;

        //Timeshift to sale period
        await timeTravelFixture(saleStartTime + 1);

        //Get usdt price
        const USDTPrice = await presale.getPriceInUSDT(tokensToPurchase);

        //Add allowance to contract
        await USDT.connect(users.creator).approve(presale.address, USDTPrice);

        //Buy with USDT
        const buyWithUSDTTx = presale.connect(users.creator).buyWithUSDT(tokensToPurchase);

        //Assert transaction was successful
        await expect(buyWithUSDTTx).not.to.be.reverted;

        expect(await buyWithUSDTTx)
          .to.emit(presale, "TokensBought")
          .withArgs(users.creator.address, "USDT", tokensToPurchase, USDTPrice, USDTPrice);
      });
    });

    describe("'claim' function", function () {
      it("should increase purchased tokens amount and transfer payment to owner", async function () {
        //Set values
        const { presale, users, saleStartTime, saleEndTime, CHR } = await deployPresaleFixture();
        const tokensToPurchase = 1000n;
        const claimStartTime = saleEndTime + 1;

        //Timeshift to sale period
        await timeTravelFixture(saleStartTime + 1);

        //Start claim
        await startClaimFixture(
          presale,
          CHR,
          users.creator,
          users.presaleOwner,
          claimStartTime,
          tokensToPurchase
        );

        //Purchase some tokens
        await purchaseTokensFixture(presale, users.creator, tokensToPurchase);

        //Get values before transaction
        const tokenBalanceBefore = await CHR.balanceOf(users.creator.address);

        //Timeshift to claim period
        await timeTravelFixture(claimStartTime + 1);

        //Claim tokens
        const claimTx = presale.connect(users.creator).claim();

        //Assert transaction was successful
        await expect(claimTx).not.to.be.reverted;

        //Get values after transaction
        const tokenBalanceAfter = await CHR.balanceOf(users.creator.address);
        const decimals = await CHR.decimals();

        //Assert values with expected
        expect(await presale.hasClaimed(users.creator.address)).to.equal(true);
        expect(tokenBalanceAfter).to.equal(
          tokenBalanceBefore.add(BigNumber.from(10).pow(decimals).mul(tokensToPurchase))
        );
      });

      it("should revert if called before claim start time", async function () {
        //Set values
        const { presale, users, saleStartTime, saleEndTime, CHR } = await deployPresaleFixture();
        const tokensToPurchase = 1000;
        const claimStartTime = saleEndTime + 1;

        //Timeshift to sale period
        await timeTravelFixture(saleStartTime + 1);

        //Start claim
        await startClaimFixture(
          presale,
          CHR,
          users.creator,
          users.presaleOwner,
          claimStartTime,
          tokensToPurchase
        );

        //Purchase some tokens
        await purchaseTokensFixture(presale, users.creator, tokensToPurchase);

        //Claim tokens
        const claimTx = presale.connect(users.creator).claim();

        //Assert transaction was reverted
        await expect(claimTx).to.be.revertedWithCustomError(presale, "InvalidTimeframe");
      });

      it("should revert if claim start time is not set", async function () {
        //Set values
        const { presale, users, saleStartTime } = await deployPresaleFixture();
        const tokensToPurchase = 1000;

        //Timeshift to sale period
        await timeTravelFixture(saleStartTime + 1);

        //Purchase some tokens
        await purchaseTokensFixture(presale, users.creator, tokensToPurchase);

        //Claim tokens
        const claimTx = presale.connect(users.creator).claim();

        //Assert transaction was reverted
        await expect(claimTx).to.be.revertedWithCustomError(presale, "InvalidTimeframe");
      });

      it("should revert if no tokens purchased", async function () {
        //Set values
        const { presale, users, saleStartTime, saleEndTime, CHR } = await deployPresaleFixture();
        const tokensToPurchase = 1000;
        const claimStartTime = saleEndTime + 1;

        //Timeshift to sale period
        await timeTravelFixture(saleStartTime + 1);

        //Start claim
        await startClaimFixture(
          presale,
          CHR,
          users.creator,
          users.presaleOwner,
          claimStartTime,
          tokensToPurchase
        );

        //Timeshift to claim period
        await timeTravelFixture(claimStartTime + 1);

        //Claim tokens
        const claimTx = presale.connect(users.creator).claim();

        //Assert transaction was reverted
        await expect(claimTx).to.be.revertedWithCustomError(presale, "NothingToClaim");
      });

      it("should revert if already claimed", async function () {
        //Set values
        const { presale, users, saleStartTime, saleEndTime, CHR } = await deployPresaleFixture();
        const tokensToPurchase = 1000;
        const claimStartTime = saleEndTime + 1;

        //Timeshift to sale period
        await timeTravelFixture(saleStartTime + 1);

        //Start claim
        await startClaimFixture(
          presale,
          CHR,
          users.creator,
          users.presaleOwner,
          claimStartTime,
          tokensToPurchase
        );

        //Purchase some tokens
        await purchaseTokensFixture(presale, users.creator, tokensToPurchase);

        //Timeshift to claim period
        await timeTravelFixture(claimStartTime + 1);

        //Claim tokens
        await presale.connect(users.creator).claim();

        //Claim tokens again
        const claimTx = presale.connect(users.creator).claim();

        //Assert transaction was reverted
        await expect(claimTx).to.be.revertedWithCustomError(presale, "AlreadyClaimed");
      });

      it("should emit TokensClaimed event", async function () {
        //Set values
        const { presale, users, saleStartTime, saleEndTime, CHR } = await deployPresaleFixture();
        const tokensToPurchase = 1000;
        const claimStartTime = saleEndTime + 1;

        //Timeshift to sale period
        await timeTravelFixture(saleStartTime + 1);

        //Start claim
        await startClaimFixture(
          presale,
          CHR,
          users.creator,
          users.presaleOwner,
          claimStartTime,
          tokensToPurchase
        );

        //Purchase some tokens
        await purchaseTokensFixture(presale, users.creator, tokensToPurchase);

        //Timeshift to claim period
        await timeTravelFixture(claimStartTime + 1);

        //Claim tokens
        const claimTx = await presale.connect(users.creator).claim();

        //Assert transaction was successful
        await expect(claimTx).not.to.be.reverted;

        //Assert event was emitted
        expect(claimTx).to.emit(presale, "TokensClaimed").withArgs(users.creator.address, tokensToPurchase);
      });
    });

    describe("'getPriceInETH' function", function () {
      it("should calculate correct wei price", async function () {
        //Set values
        const { presale, stagePrice, ChainlinkPriceFeed } = await deployPresaleFixture();
        const tokensToPurchase = 1000;

        const latestPrice = await ChainlinkPriceFeed.latestRoundData();

        //calculate expected price
        const expectedPrice = stagePrice[0]
          .mul(tokensToPurchase)
          .mul(BigNumber.from(10).pow(20))
          .div(latestPrice[1]);

        //Calculate wei price
        const getPriceInETHTx = presale.getPriceInETH(tokensToPurchase);

        //Assert transaction was successful
        await expect(getPriceInETHTx).not.to.be.reverted;

        //Assert price with expected
        expect(await getPriceInETHTx).to.equal(expectedPrice);
      });
    });

    describe("'getPriceInUSDT' function", function () {
      it("should calculate correct USDT price", async function () {
        //Set values
        const { presale, stagePrice } = await deployPresaleFixture();
        const tokensToPurchase = 1000;

        //calculate expected price
        const expectedPrice = stagePrice[0].mul(tokensToPurchase);

        //Calculate USDT price
        const getPriceInUSDTTx = presale.getPriceInUSDT(tokensToPurchase);

        //Assert transaction was successful
        await expect(getPriceInUSDTTx).not.to.be.reverted;

        //Assert price with expected
        expect(await getPriceInUSDTTx).to.equal(expectedPrice);
      });
    });
  });
});
