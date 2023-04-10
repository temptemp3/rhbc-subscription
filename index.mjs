import { loadStdlib } from "@reach-sh/stdlib";
import * as l1Backend from "./build/index.L1.mjs";
import * as l2Backend from "./build/index.L2.mjs";
import * as l2bBackend from "./build/index.L2b.mjs";
import * as l3Backend from "./build/index.L3.mjs";
const stdlib = loadStdlib(process.env);

const erc20ABIHelper = (erc20ABI, ctcInfo) => ({
  getAllowance: async (address) => {
    console.log("Getting allowance for", address);
    const allowance = await erc20ABI.allowance(address, ctcInfo);
    console.log({ allowance });
    return allowance;
  },
  doApprove: async (address, amount) => {
    console.log(
      `Address ${address} is approving ${ctcInfo} to spend up to ${amount} Zorkmids.}`
    );
    const t = await erc20ABI.approve(ctcInfo, amount);
    console.log("+ Step 1: ", t);
    const r = await t.wait();
    console.log("+ Step 2: ", r);
  },
});

const showBalances = async (name, acc, tok) => {
  const netBalance = stdlib.formatCurrency(await acc.balanceOf());
  const tokBalance = stdlib.formatWithDecimals(await acc.balanceOf(tok), 0);
  console.log(`(${name}) Balance:`, netBalance);
  console.log(`${tok} Balance:`, tokBalance);
};

const L1a = async (backend) => {
  const startingBalance = stdlib.parseCurrency(100);

  const [accDeployer, accIssuer, ...accAttacher] = await stdlib.newTestAccounts(
    10,
    startingBalance
  );

  const myGasLimit = 5000000;
  accDeployer.setGasLimit(myGasLimit);
  accAttacher.map((el) => el.setGasLimit(myGasLimit));

  console.log("Hello, Deployer and Attachers!");

  console.log("Launching...");

  const ctcDeployer = accDeployer.contract(backend);
  const ctcAttacher = accAttacher[0].contract(backend, ctcDeployer.getInfo());

  const zorkmid = await stdlib.launchToken(accIssuer, "zorkmid", "ZMD");
  await zorkmid.mint(accAttacher[0], 240);

  const showAllBalances = async (i) => {
    await showBalances("Deployer", accDeployer, zorkmid.id);
    await showBalances("Attacher", accAttacher[i], zorkmid.id);
  };

  console.log("=== Before ===");
  await showAllBalances(0);

  console.log("Deploying contract...");

  await stdlib.withDisconnect(() =>
    ctcDeployer.p.Deployer({
      getParams: () => ({
        token: zorkmid.id, // ERC20 but need it as Token to satisfy (L1.2.2.1)
        periodCount: 12, // how many payments, ex 12
        periodAmount: 20, // how much each payment, ex 100
        periodLength: 1, // how long each payment, ex 30 days in blocks
        ttl: 1000, // time to live
      }),
      ready: () => {
        console.log("Ready!");
        stdlib.disconnect(null); // causes withDisconnect to immediately return null
      },
    })
  );

  console.log("Contract deployed!");

  await showAllBalances(0);

  console.log("Accepting contract...");

  await stdlib.withDisconnect(() =>
    ctcAttacher.p.Attacher({
      accept: () => true,
      ready: () => {
        console.log("Ready!");
        stdlib.disconnect(null); // causes withDisconnect to immediately return null
      },
    })
  );

  console.log("Contract accepted!");

  await showAllBalances(0);

  for (let i = 0; i < 12; i++) {
    console.log(`Step ${i}`);
    console.log("Claiming...");
    await ctcDeployer.a.claim(1);
    console.log("Claimed!");
    await showAllBalances(0);
  }

  console.log("Goodbye, Deployer and Attachers!");
};

const L1b = async (backend) => {
  const startingBalance = stdlib.parseCurrency(100);

  const [accDeployer, accIssuer, ...accAttacher] = await stdlib.newTestAccounts(
    10,
    startingBalance
  );

  const myGasLimit = 5000000;
  accDeployer.setGasLimit(myGasLimit);
  accAttacher.map((el) => el.setGasLimit(myGasLimit));

  console.log("Hello, Deployer and Attachers!");

  console.log("Launching...");

  const ctcDeployer = accDeployer.contract(backend);
  const ctcAttacher = accAttacher[0].contract(backend, ctcDeployer.getInfo());

  const zorkmid = await stdlib.launchToken(accIssuer, "zorkmid", "ZMD");
  await zorkmid.mint(accAttacher[0], 240);

  const showAllBalances = async (i) => {
    await showBalances("Deployer", accDeployer, zorkmid.id);
    await showBalances("Attacher", accAttacher[i], zorkmid.id);
  };

  console.log("=== Before ===");
  await showAllBalances(0);

  console.log("Deploying contract...");

  await stdlib.withDisconnect(() =>
    ctcDeployer.p.Deployer({
      getParams: () => ({
        token: zorkmid.id, // ERC20 but need it as Token to satisfy (L1.2.2.1)
        periodCount: 12, // how many payments, ex 12
        periodAmount: 20, // how much each payment, ex 100
        periodLength: 1, // how long each payment, ex 30 days in blocks
        ttl: 1000, // time to live
      }),
      ready: () => {
        console.log("Ready!");
        stdlib.disconnect(null); // causes withDisconnect to immediately return null
      },
    })
  );

  console.log("Contract deployed!");

  await showAllBalances(0);

  console.log("Accepting contract...");

  await stdlib.withDisconnect(() =>
    ctcAttacher.p.Attacher({
      accept: () => true,
      ready: () => {
        console.log("Ready!");
        stdlib.disconnect(null); // causes withDisconnect to immediately return null
      },
    })
  );

  console.log("Contract accepted!");

  await showAllBalances(0);

  // --------------------------------
  // XXX changed this part
  // --------------------------------
  console.log("Claiming...");
  await stdlib.wait(12);
  await ctcDeployer.a.claim(12);
  console.log("Claimed!");
  await showAllBalances(0);
  // --------------------------------

  console.log("Goodbye, Deployer and Attachers!");
};

const L2a = async (backend) => {
  const startingBalance = stdlib.parseCurrency(100);

  const [accDeployer, accIssuer, ...accAttacher] = await stdlib.newTestAccounts(
    5,
    startingBalance
  );

  const myGasLimit = 5000000;
  accDeployer.setGasLimit(myGasLimit);
  accAttacher.map((el) => el.setGasLimit(myGasLimit));

  console.log("Hello, Deployer and Attachers!");

  console.log("Launching...");

  const ctcDeployer = accDeployer.contract(backend);
  const ctcAttacher = accAttacher[0].contract(backend, ctcDeployer.getInfo());

  const zorkmid = await stdlib.launchToken(accIssuer, "zorkmid", "ZMD");
  await zorkmid.mint(accAttacher[0], 240);

  const showAllBalances = async (i) => {
    await showBalances("Deployer", accDeployer, zorkmid.id);
    await showBalances("Attacher", accAttacher[i], zorkmid.id);
  };

  console.log("=== Before ===");
  await showAllBalances(0);

  console.log("Deploying contract...");

  await stdlib.withDisconnect(() =>
    ctcDeployer.p.Deployer({
      getParams: () => ({
        token: zorkmid.id, // ERC20 but need it as Token to satisfy (L1.2.2.1)
        periodCount: 12, // how many payments, ex 12
        periodAmount: 20, // how much each payment, ex 100
        periodLength: 1, // how long each payment, ex 30 days in blocks
      }),
      ready: () => {
        console.log("Ready!");
        stdlib.disconnect(null); // causes withDisconnect to immediately return null
      },
    })
  );

  console.log("Contract deployed!");

  await showAllBalances(0);

  console.log("Accepting contract...");

  await stdlib.wait(10);
  console.log(`contract ${await ctcAttacher.getInfo()}`);

  console.log((await ctcAttacher.v.state())[1]);

  const attacherAddress = accAttacher[0].getAddress();
  const deployerAddress = accDeployer.getAddress();

  console.log(`subscription(address):`);
  console.log((await ctcAttacher.v.subscription(attacherAddress))[1]);

  const res = await ctcAttacher.a.subscribe();

  console.log(`res ${res}`);

  console.log((await ctcAttacher.v.state())[1]);

  console.log(`address: ${attacherAddress}`);

  console.log((await ctcAttacher.v.subscription(attacherAddress))[1]);

  console.log("Contract accepted!");

  await showAllBalances(0);

  // --------------------------------
  // XXX changed this part
  // --------------------------------
  for (let i = 0; i < 12; i++) {
    console.log(`Step ${i}`);
    console.log("Claiming...");
    console.log((await ctcAttacher.v.subscription(attacherAddress))[1]);
    await ctcDeployer.a.claim(attacherAddress, 1);
    console.log((await ctcAttacher.v.subscription(attacherAddress))[1]);
    console.log("Claimed!");
    await showAllBalances(0);
  }
  // --------------------------------
  console.log("Goodbye, Deployer and Attachers!");
};
const L2b = async (backend) => {
  const startingBalance = stdlib.parseCurrency(100);

  const [accDeployer, accIssuer, ...accAttacher] = await stdlib.newTestAccounts(
    5,
    startingBalance
  );

  const myGasLimit = 5000000;
  accDeployer.setGasLimit(myGasLimit);
  accAttacher.map((el) => el.setGasLimit(myGasLimit));

  console.log("Hello, Deployer and Attachers!");

  console.log("Launching...");

  const ctcDeployer = accDeployer.contract(backend);
  const ctcAttacher = accAttacher[0].contract(backend, ctcDeployer.getInfo());

  const zorkmid = await stdlib.launchToken(accIssuer, "zorkmid", "ZMD");
  await zorkmid.mint(accAttacher[0], 240);

  const showAllBalances = async (i) => {
    await showBalances("Deployer", accDeployer, zorkmid.id);
    await showBalances("Attacher", accAttacher[i], zorkmid.id);
  };

  console.log("=== Before ===");
  await showAllBalances(0);

  console.log("Deploying contract...");

  await stdlib.withDisconnect(() =>
    ctcDeployer.p.Deployer({
      getParams: () => ({
        token: zorkmid.id, // ERC20 but need it as Token to satisfy (L1.2.2.1)
        periodCount: 12, // how many payments, ex 12
        periodAmount: 20, // how much each payment, ex 100
        periodLength: 1, // how long each payment, ex 30 days in blocks
      }),
      ready: () => {
        console.log("Ready!");
        stdlib.disconnect(null); // causes withDisconnect to immediately return null
      },
    })
  );

  console.log("Contract deployed!");

  await showAllBalances(0);

  console.log("Accepting contract...");

  await stdlib.wait(10);
  console.log(`contract ${await ctcAttacher.getInfo()}`);

  console.log((await ctcAttacher.v.state())[1]);

  const attacherAddress = accAttacher[0].getAddress();
  const deployerAddress = accDeployer.getAddress();

  console.log(`subscription(address):`);
  console.log((await ctcAttacher.v.subscription(attacherAddress))[1]);

  const res = await ctcAttacher.a.subscribe();

  console.log(`res ${res}`);

  console.log((await ctcAttacher.v.state())[1]);

  console.log(`address: ${attacherAddress}`);

  console.log((await ctcAttacher.v.subscription(attacherAddress))[1]);

  console.log("Contract accepted!");

  await showAllBalances(0);

  // --------------------------------
  // XXX changed this part
  // --------------------------------
  await stdlib.wait(20); // wait for lower gas price
  console.log("Claiming...");
  console.log((await ctcAttacher.v.subscription(attacherAddress))[1]);
  await ctcDeployer.a.claim(attacherAddress, 12);
  console.log((await ctcAttacher.v.subscription(attacherAddress))[1]);
  console.log("Claimed!");
  await showAllBalances(0);
  // --------------------------------
  console.log("Goodbye, Deployer and Attachers!");
};
const L2c = async (backend) => {
  const startingBalance = stdlib.parseCurrency(100);

  const [accDeployer, accIssuer, ...accAttacher] = await stdlib.newTestAccounts(
    5,
    startingBalance
  );

  const myGasLimit = 5000000;
  accDeployer.setGasLimit(myGasLimit);
  accAttacher.map((el) => el.setGasLimit(myGasLimit));

  console.log("Hello, Deployer and Attachers!");

  console.log("Launching...");

  const ctcDeployer = accDeployer.contract(backend);
  const ctcAttacher = accAttacher[0].contract(backend, ctcDeployer.getInfo());

  const zorkmid = await stdlib.launchToken(accIssuer, "zorkmid", "ZMD");
  await zorkmid.mint(accAttacher[0], 240);

  const showAllBalances = async (i) => {
    await showBalances("Deployer", accDeployer, zorkmid.id);
    await showBalances("Attacher", accAttacher[i], zorkmid.id);
  };

  console.log("=== Before ===");
  await showAllBalances(0);

  console.log("Deploying contract...");

  await stdlib.withDisconnect(() =>
    ctcDeployer.p.Deployer({
      getParams: () => ({
        token: zorkmid.id, // ERC20 but need it as Token to satisfy (L1.2.2.1)
        periodCount: 12, // how many payments, ex 12
        periodAmount: 20, // how much each payment, ex 100
        periodLength: 1, // how long each payment, ex 30 days in blocks
      }),
      ready: () => {
        console.log("Ready!");
        stdlib.disconnect(null); // causes withDisconnect to immediately return null
      },
    })
  );

  console.log("Contract deployed!");

  await showAllBalances(0);

  console.log("Accepting contract...");

  await stdlib.wait(10);
  console.log(`contract ${await ctcAttacher.getInfo()}`);

  console.log((await ctcAttacher.v.state())[1]);

  const attacherAddress = accAttacher[0].getAddress();
  const deployerAddress = accDeployer.getAddress();

  console.log(`subscription(address):`);
  console.log((await ctcAttacher.v.subscription(attacherAddress))[1]);

  const res = await ctcAttacher.a.subscribe();

  console.log(`res ${res}`);

  console.log((await ctcAttacher.v.state())[1]);

  console.log(`address: ${attacherAddress}`);

  console.log((await ctcAttacher.v.subscription(attacherAddress))[1]);

  console.log("Contract accepted!");

  await showAllBalances(0);

  // --------------------------------
  // XXX changed this part
  // --------------------------------
  await stdlib.wait(20); // wait for lower gas price
  console.log("Claiming...");
  console.log((await ctcAttacher.v.subscription(attacherAddress))[1]);
  await ctcDeployer.a.claim(attacherAddress, 6);
  console.log((await ctcAttacher.v.subscription(attacherAddress))[1]);
  console.log("Claimed!");
  await showAllBalances(0);
  // --------------------------------
  // XXX added this part
  // --------------------------------
  await stdlib.wait(20); // wait for lower gas price
  console.log("Cancelling...");
  console.log((await ctcAttacher.v.subscription(attacherAddress))[1]);
  await ctcAttacher.a.cancel();
  console.log((await ctcAttacher.v.subscription(attacherAddress))[1]);
  console.log("Cancelled!");
  await showAllBalances(0);
  // --------------------------------
  console.log("Goodbye, Deployer and Attachers!");
};

// L2b
const L2d = async (backend) => {
  const startingBalance = stdlib.parseCurrency(100);

  const [accDeployer, accIssuer, ...accAttacher] = await stdlib.newTestAccounts(
    5,
    startingBalance
  );

  const myGasLimit = 5000000;
  accDeployer.setGasLimit(myGasLimit);
  accAttacher.map((el) => el.setGasLimit(myGasLimit));

  console.log("Hello, Deployer and Attachers!");

  console.log("Launching...");

  const ctcDeployer = accDeployer.contract(backend);

  const ctcAttacher = accAttacher[0].contract(backend, ctcDeployer.getInfo());

  const zorkmid = await stdlib.launchToken(accIssuer, "zorkmid", "ZMD");
  await zorkmid.mint(accAttacher[0], 240 * 12);

  const showAllBalances = async (i) => {
    await showBalances("Deployer", accDeployer, zorkmid.id);
    await showBalances("Attacher", accAttacher[i], zorkmid.id);
  };

  console.log("=== Before ===");
  await showAllBalances(0);

  console.log("Deploying contract...");

  await stdlib.withDisconnect(() =>
    ctcDeployer.p.Deployer({
      getParams: () => ({
        token: zorkmid.id, // ERC20 but need it as Token to satisfy (L1.2.2.1)
      }),
      ready: () => {
        console.log("Ready!");
        stdlib.disconnect(null); // causes withDisconnect to immediately return null
      },
    })
  );

  console.log("Contract deployed!");

  await showAllBalances(0);

  console.log("Accepting contract...");

  await stdlib.wait(1); // wait for lower gas price

  console.log(`contract ${await ctcAttacher.getInfo()}`);

  console.log((await ctcAttacher.v.state())[1]);

  const attacherAddress = accAttacher[0].getAddress();
  const deployerAddress = accDeployer.getAddress();

  // announce provider service

  console.log("Announcing provider service...");

  for (let i = 0; i < 12; i++) {
    await ctcDeployer.a.announce(
      /*periodCount*/ 12,
      /*periodAmount*/ 20,
      /*periodLength*/ 1
    );
  }

  console.log((await ctcAttacher.v.state())[1]);

  // --------------------------------
  // listening for events
  // --------------------------------
  const { e } = ctcDeployer;
  const listenForEvents = async (evt) => {
    while (true) {
      await e[evt].next().then(console.log);
    }
  };
  const listenForAnnouncement = () => listenForEvents("announcement");
  const listenForJoin = () => listenForEvents("join");
  const listenForRedeem = () => listenForEvents("redeem");
  listenForAnnouncement();
  listenForJoin();
  listenForRedeem();
  // --------------------------------

  await stdlib.wait(1); // wait for lower gas price

  for (let i = 0; i < 12; i++) {
    console.log(`Subscribing to service ${i}...`);
    const res = await ctcAttacher.a.subscribe(deployerAddress, i);
    console.log({ res });
    console.log("Subscribed!");
    await stdlib.wait(1);
  }

  await showAllBalances(0);

  // --------------------------------
  // XXX changed this part
  // --------------------------------
  for (let j = 0; j < 12; j++) {
    for (let i = 0; i < 12; i++) {
      console.log(`Step ${i}`);
      console.log("Claiming...");
      console.log((await ctcAttacher.v.subscription(attacherAddress))[1]);
      await ctcDeployer.a.claim(deployerAddress, j, attacherAddress, 1);
      console.log((await ctcAttacher.v.subscription(attacherAddress))[1]);
      console.log("Claimed!");
      await showAllBalances(0);
    }
  }
  // --------------------------------
  console.log("Goodbye, Deployer and Attachers!");
};

const L3a = async (backend) => {
  const startingBalance = stdlib.parseCurrency(100);

  const [accDeployer, accIssuer, ...accAttacher] = await stdlib.newTestAccounts(
    5,
    startingBalance
  );

  const myGasLimit = 5000000;
  accDeployer.setGasLimit(myGasLimit);
  accAttacher.map((el) => el.setGasLimit(myGasLimit));

  console.log("Hello, Deployer and Attachers!");

  console.log("Launching...");

  const ctcDeployer = accDeployer.contract(backend);
  const ctcAttacher = accAttacher[0].contract(backend, ctcDeployer.getInfo());

  const zorkmid = await stdlib.launchToken(accIssuer, "zorkmid", "ZMD");
  await zorkmid.mint(accAttacher[0], 240);

  const showAllBalances = async (i) => {
    await showBalances("Deployer", accDeployer, zorkmid.id);
    await showBalances("Attacher", accAttacher[i], zorkmid.id);
  };

  console.log("=== Before ===");
  await showAllBalances(0);

  console.log("Deploying contract...");

  const periodCount = 12;
  const periodAmount = 20;

  await stdlib.withDisconnect(() =>
    ctcDeployer.p.Deployer({
      getParams: () => ({
        token: zorkmid.id, // ERC20 but need it as Token to satisfy (L1.2.2.1)
        periodCount, // how many payments, ex 12
        periodAmount, // how much each payment, ex 100
        periodLength: 1, // how long each payment, ex 30 days in blocks
      }),
      ready: stdlib.disconnect, // causes withDisconnect to immediately return null
    })
  );

  const {
    e: { join, redeem },
  } = ctcDeployer;

  join.next().then(console.log);
  redeem.next().then(console.log);

  const Smarty = await ctcDeployer.getInfo();

  console.log(Smarty);

  console.log("Contract deployed!");

  await showAllBalances(0);

  const totalAmount = periodCount * periodAmount;

  console.log(`Attacher is allowing ${totalAmount}`);

  const { ethers } = stdlib;
  const ERC20 = [
    "function approve(address _spender, uint256 _value) public returns (bool success)",
    "function allowance(address _owner, address _spender) public view returns (uint256 remaining)",
  ];
  const ZorkmidRaw = new ethers.Contract(
    zorkmid.id,
    ERC20,
    accAttacher[0].networkAccount
  );

  const { getAllowance, doApprove } = erc20ABIHelper(ZorkmidRaw, Smarty);

  await doApprove(accAttacher[0].getAddress(), totalAmount);

  await showAllBalances(0);

  console.log("Accepting contract...");

  await stdlib.wait(10);
  console.log(`contract ${Smarty}`);

  console.log((await ctcAttacher.v.state())[1]);

  const attacherAddress = accAttacher[0].getAddress();
  const deployerAddress = accDeployer.getAddress();

  console.log(`subscription(address):`);
  console.log((await ctcAttacher.v.subscription(attacherAddress))[1]);

  const res = await ctcAttacher.a.subscribe();

  console.log(`res ${res}`);

  console.log((await ctcAttacher.v.state())[1]);

  console.log(`address: ${attacherAddress}`);

  console.log((await ctcAttacher.v.subscription(attacherAddress))[1]);

  console.log("Contract accepted!");

  await showAllBalances(0);

  // --------------------------------
  // XXX changed this part
  // --------------------------------
  console.log(
    `allowance: ${await getAllowance(await accAttacher[0].getAddress())}`
  );
  console.log((await ctcAttacher.v.subscription(attacherAddress))[1]);

  await stdlib.wait(20); // wait for lower gas price
  for (let i = 0; i < 12; i++) {
    console.log("Claiming...");

    await ctcDeployer.a.claim(attacherAddress, 1);

    console.log(
      stdlib.formatWithDecimals(
        await getAllowance(await accAttacher[0].getAddress()),
        0
      )
    );

    // approve zero here

    console.log(await getAllowance(await accAttacher[0].getAddress()));

    console.log((await ctcAttacher.v.subscription(attacherAddress))[1]);

    console.log("Claimed!");
    await showAllBalances(0);
  }
  // --------------------------------
  // XXX cancel was here
  // --------------------------------
  console.log("Goodbye, Deployer and Attachers!");
};
const main = async () => {
  console.log(`L1 (a): claim in 12 steps`);
  await L1a(l1Backend);
  console.log(`L1 (b): claim in 1 step`);
  await L1b(l1Backend);
  console.log(`L2 (a): claim in 12 steps`);
  await L2a(l2Backend);
  console.log(`L2 (b): claim in 1 steps`);
  await L2b(l2Backend);
  console.log(`L2 (c): claim in 6 steps then cancel`);
  await L2c(l2Backend);
  console.log(`L2 (d): L2b`);
  await L2d(l2bBackend);
  console.log(`L3 (a):`);
  console.log(`L3 (a): claim in 6 steps`);
  await L3a(l3Backend);
};

main();
