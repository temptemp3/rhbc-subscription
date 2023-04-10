"reach 0.1";

// FUNC

const max = (a, b) => (a > b ? a : b);

const makeTokenObj = (token) =>
  remote(token, {
    transferFrom: Fun([Address, Address, UInt], Bool),
    allowance: Fun([Address, Address], UInt),
  });

// FUN

const fReady = Fun([], Null);
const fClaim = Fun([UInt], Bool);
const fAccept = Fun([], Bool);
const fAnnounce = Fun([UInt, UInt, UInt], Bool);
const fSubscribe = Fun([], Bool);
const fSubscribe4 = Fun([Address, UInt], Bool);
const fClaim2 = Fun([Address, UInt], Bool);
const fClaim2b = Fun([Address, UInt, Address, UInt], Bool);
const fCancel = Fun([], Bool);
const fCancel2b = Fun([Address, UInt], Bool);
const fGetParams = (Params) => Fun([], Params);
const fState = (State) => Fun([], State);

// TYPES

/*
 * ProviderService
 */
const ProviderService = Struct([
  ["periodCount", UInt],
  ["periodAmount", UInt],
  ["periodLength", UInt],
  ["subscriberCount", UInt],
]);

/*
 * Subscription
 */
const Subscription = Tuple(UInt, UInt);

/*
 * BaseDetails
 * Provider service term details for 1:1 or 1:N subscriptions
 */
const BaseDetails = Object({
  periodCount: UInt, // how many payments, ex 12
  periodAmount: UInt, // how much each payment, ex 100
  periodLength: UInt, // how long each payment, ex 30 days in blocks
});

/*
 * L1DetailsExtension
 * Provider service term details extension for 1:1 subscriptions
 */
const L1DetailsExtension = Object({
  token: Token, // ERC20 but need it as Token to satisfy (L1.2.2.1)
  ttl: UInt, // time to live
});

/*
 * L1Details
 * Provider service term details for 1:1 subscriptions
 */
const L1Details = Object({
  ...Object.fields(BaseDetails),
  ...Object.fields(L1DetailsExtension),
});

const L2DetailsExtension = Object({
  token: Token,
});

const L2Details = Object({
  ...Object.fields(BaseDetails),
  ...Object.fields(L2DetailsExtension),
});

const L3DetailsExtension = Object({
  token: Contract,
});

const L3Details = Object({
  ...Object.fields(BaseDetails),
  ...Object.fields(L3DetailsExtension),
});

const L4Details = Object({
  ...Object.fields(L2DetailsExtension),
});

const L5Details = Object({
  ...Object.fields(L3DetailsExtension),
});

/*
 * L1Params
 * Provider service term parameters for 1:1 subscriptions
 */
const L1Params = Object({
  ...Object.fields(L1Details),
});

/*
 * L2Params
 * Provider service term parameters for 1:N subscriptions
 */
const L2Params = Object({
  ...Object.fields(L2Details),
});

/*
 * L3Params
 * Provider service term parameters for 1:N subscriptions using ERC20 abi
 */
const L3Params = Object({
  ...Object.fields(L3Details),
});

/*
 * L4Params
 * Provider service term parameters for N:M subscriptions
 */
const L4Params = Object({
  ...Object.fields(L4Details),
});

/*
 * L5Params
 * Provider service term parameters for N:M subscriptions using ERC20 abi
 */
const L5Params = Object({
  ...Object.fields(L5Details),
});

/*
 * BaseState
 * Provider service term state for 1:1 or 1:N subscriptions
 */
const BaseState = Struct([
  ["subscriptionProvider", Address],
  ["periodCount", UInt],
  ["periodAmount", UInt],
  ["periodLength", UInt],
  ["subscriberCount", UInt],
  ["safeAmount", UInt],
]);

// L1State None

/*
 * L2StateExtension
 * Provider service term state extension for 1:N subscriptions
 * Add token to state
 */
const L2StateExtension = Struct([["token", Token]]);

/*
 * L2State
 * Provider service term state for 1:N subscriptions
 * BaseState + L2StateExtension
 */
const L2State = Struct([
  ...Struct.fields(BaseState),
  ...Struct.fields(L2StateExtension),
]);

/*
 * L3StateExtension
 * Provider service term state extension for 1:N subscriptions
 * Token is a Contract (ERC20)
 */
const L3StateExtension = Struct([["token", Contract]]);

/*
 * L3State
 * Provider service term state for 1:N subscriptions
 * BaseState + L3StateExtension
 */
const L3State = Struct([
  ...Struct.fields(BaseState),
  ...Struct.fields(L3StateExtension),
]);

/*
 * L4StateExtension
 * Provider service term state extension for N:M subscriptions
 */
const L4StateExtension = Struct([
  ["providerCount", UInt],
  ["subscriberCount", UInt],
  ["safeAmount", UInt],
  ["safeSize", UInt],
]);

/*
 * L4State
 * Provider service term state for N:M subscriptions
 * L2State + L4StateExtension
 */
const L4State = Struct([
  ...Struct.fields(L2StateExtension),
  ...Struct.fields(L4StateExtension),
]);

/*
 * L5State
 * Provider service term state for N:M subscriptions
 * Alias L4State
 */
const L5State = Struct([
  ...Struct.fields(L3StateExtension),
  ...Struct.fields(L4StateExtension),
]);

// PARTICIPANTS

const Participants = (Params) => [
  Participant("Deployer", {
    ready: fReady,
    getParams: fGetParams(Params),
  }),
];

const L1Participants = () => [
  Participant("Attacher", {
    ready: fReady,
    accept: fAccept,
  }),
];

// VIEW

const l2View = {
  state: fState(L2State),
  subscription: Fun([Address], Tuple(UInt, UInt)),
};

const l3View = {
  ...l2View,
  state: fState(L3State),
};

const l4View = {
  state: fState(L4State),
  subscription: Fun([Address, UInt, Address], Subscription),
};

const l5View = {
  state: fState(L5State),
  subscription: Fun([Address, UInt, Address], Subscription),
};

// API

const l1Api = {
  claim: fClaim,
};

const l2Api = {
  claim: fClaim2,
  subscribe: fSubscribe,
  cancel: fCancel,
};

const l3Api = {
  claim: fClaim2,
  subscribe: fSubscribe,
};

const l4Api = {
  claim: fClaim2b,
  announce: fAnnounce,
  subscribe: fSubscribe4,
  cancel: fCancel2b,
};

const l5Api = {
  claim: fClaim2b,
  announce: fAnnounce,
  subscribe: fSubscribe4,
};

// EVENT

const L3Events = () => [
  Events({
    join: [Address, Contract, UInt, UInt, UInt],
    redeem: [Address, Address, UInt],
  }),
];

const L4Events = () => [
  Events({
    join: [Address, UInt, Address],
    redeem: [Address, UInt, Address, UInt],
    announcement: [Address, UInt, UInt, UInt, UInt],
  }),
];

// INIT

const L1Init = () => {
  setOptions({
    connectors: [ETH],
  });
  const p = [...Participants(L1Params), ...L1Participants()];
  const a = [API(l1Api)];
  init();
  return [p, a];
};

const L2Init = () => {
  setOptions({
    connectors: [ETH],
  });
  const p = Participants(L2Params);
  const v = [View(l2View)];
  const a = [API(l2Api)];
  const s = [L2State];
  init();
  return [p, v, a, s];
};

const L3Init = () => {
  setOptions({
    connectors: [ETH],
  });
  const p = Participants(L3Params);
  const v = [View(l3View)];
  const a = [API(l3Api)];
  const e = L3Events();
  const s = [L3State];
  init();
  return [p, v, a, e, s];
};

const L4Init = () => {
  setOptions({
    connectors: [ETH],
  });
  const p = Participants(L4Params);
  const v = [View(l4View)];
  const a = [API(l4Api)];
  const e = L4Events();
  const s = [L4State];
  init();
  return [p, v, a, e, s];
};

const L5Init = () => {
  setOptions({
    connectors: [ETH],
  });
  const p = Participants(L5Params);
  const v = [View(l5View)];
  const a = [API(l5Api)];
  const e = L4Events();
  const s = [L5State];
  init();
  return [p, v, a, e, s];
};

/*
 * L1.1 Setup and scaffold ✅
 * L1.2 Use 2 particpants ✅
 * L1.2.1 Deployer ✅
 * L1.1.1.1 Sets perameters such as length and amount of each payment ✅
 * L1.2.2 Attacher ✅
 * L1.2.2.1 If attacher accepts they should pay large amount into contract ✅
 * L1.2.2.2 If attacher rejects exit contract ✅
 * L1.3 The contract should pay out regular amount, subscription fee, to the Deployer ✅
 * L1.4 Display status messages ✅
 * L1.4.1 Show balance before contract ✅
 * L1.4.2 Output boolean that Attacher accepts the terms or not ✅
 * L1.4.3 Log activity ✅
 * L1.4.4 Show balance after contract ✅
 */
export const L1 = Reach.App(() => {
  const [[Provider, Subscriber], [a]] = L1Init();
  // The first one to publish deploys the contract
  Provider.only(() => {
    const { token, periodCount, periodAmount, periodLength, ttl } = declassify(
      interact.getParams()
    );
    // checks
  });
  Provider.publish(token, periodCount, periodAmount, periodLength, ttl);
  Provider.interact.ready();
  commit();
  // The second one to publish always attaches
  Subscriber.only(() => {
    const accepts = declassify(interact.accept());
  });
  Subscriber.publish(accepts)
    .pay([[periodAmount * periodCount, token]])
    .timeout(relativeTime(ttl), () => {
      // (L1.2.2.2) Attached does not accept terms, non-participation
      Anybody.publish();
      commit();
      exit();
    });
  if (!accepts) {
    // (L1.2.2.2) Attached does not accept terms, participation
    transfer([[periodAmount * periodCount, token]]).to(Subscriber);
    commit();
    exit();
  }
  Subscriber.interact.ready();

  const [remaining, lastTime] = parallelReduce([
    periodAmount * periodCount,
    thisConsensusTime(),
  ])
    .while(true)
    .invariant(balance() == 0, "balance is accurate")
    .invariant(balance(token) == remaining, "token balance is accurate")
    // api: claim
    // input: proposed amount of periods to claim
    // output: true if claim was successful
    .define(() => {
      const claimAmount = (msg) => msg * periodAmount;
      const claimDelta = (msg) => msg * periodLength;
    })
    .api_(a.claim, (msg) => {
      check(claimAmount(msg) <= remaining, "not enough remaining");
      return [
        (k) => {
          transfer([[claimAmount(msg), token]]).to(Provider);
          enforce(
            thisConsensusTime() >= lastTime + claimDelta(msg),
            "not enough time has passed"
          );
          k(true);
          return [remaining - claimAmount(msg), lastTime + claimDelta(msg)];
        },
      ];
    });
  commit();
  exit();
});

/*
 * L2.1 Use APIs and ParallelReduce ✅
 * L2.1.1 Allow many subscribers ✅
 * L2.2 Contract should start with a years worth of tokens for each subscriber ✅
 * L2.2.1 Add API function ✅
 * L2.2.2 Variable, set in parameters ✅
 * L2.3 Store users and their subscription amounts in a Map ✅
 * L2.3.1 Check if balances are accurate ✅
 * L2.3.2 Use View to show provider terms ✅
 * L2.3.3 Only the provider claims tokens ✅
 * L2.3.4 Subscriber can cancel at any time ✅
 * L2.3.4.1 If they cancel, they get their tokens back ✅
 * L2.3.4.2 If they cancel, remaining set to zero (not removed from map) ✅
 * L2.3.5 Script display messages ✅
 * L2.3.5.1 Account balances before and after contract ✅
 * L2.3.5.2 Withdrawal message ✅
 * L2.3.5.3 Claim message ✅
 * L2.3.5.4 Final outcome :✅
 */

export const L2 = Reach.App(() => {
  const [[Provider], [v], [a], [State]] = L2Init();
  // The first one to publish deploys the contract
  Provider.only(() => {
    const { token, periodCount, periodAmount, periodLength } = declassify(
      interact.getParams()
    );
  });
  Provider.publish(token, periodCount, periodAmount, periodLength).check(() => {
    check(periodCount > 0, "periodCount must be greater than 0");
    check(periodAmount > 0, "periodAmount must be greater than 0");
    check(periodLength > 0, "periodLength must be greater than 0");
  });
  Provider.interact.ready();

  const subscriptionM = new Map(Tuple(UInt, UInt));

  const initialState = {
    subscriptionProvider: Provider, // constant, provider address
    token, // constant, token to claim
    periodCount, // constant, number of periods
    periodAmount, // constant, amount per period
    periodLength, // constant, period block time
    subscriberCount: 0, // variable, number of subscribers
    safeAmount: 0, // variable, current amount of tokens held for subscribers
    safeSize: 0, // variable, total amount of tokens received from subscribers
  };

  const [s] = parallelReduce([initialState])
    .while(true)
    .invariant(balance() == 0, "balance is accurate")
    .invariant(
      balance(token) == subscriptionM.reduce(0, (acc, w) => acc + w[0]),
      "token balance is accurate"
    )
    .invariant(
      s.subscriberCount == subscriptionM.size(),
      "subscriber count is accurate"
    )
    .invariant(
      s.safeAmount == subscriptionM.reduce(0, (acc, w) => acc + w[0]),
      "safe amount is accurate"
    )
    .invariant(s.safeSize >= s.safeAmount, "safe size is accurate")
    .paySpec([token])
    .define(() => {
      v.state.set(() => State.fromObject(s));
      v.subscription.set((addr) => fromSome(subscriptionM[addr], [0, 0]));
    })
    .define(() => {
      const depositAmount = periodAmount * periodCount;
    })
    // api: subscribe
    // input: nil
    // output: true if subscribe was successful
    .api_(a.subscribe, () => {
      check(isNone(subscriptionM[this]), "already subscribed");
      return [
        [0, [depositAmount, token]],
        (k) => {
          const subscription = subscriptionM[this];
          switch (subscription) {
            /*
            case Some: // extend subscription
              const [remaining, lastTime] = subscription;
              subscriptionM[this] = [remaining + depositAmount, lastTime];
              k(true);
              return [
                {
                  ...s,
                  safeAmount: s.safeAmount + depositAmount,
                  safeSize: max(s.safeSize, s.safeAmount + depositAmount),
                },
              ];
            */
            case Some: // impossible
              k(false);
              return [s];
            case None: // new subscription
              subscriptionM[this] = [depositAmount, thisConsensusTime()];
              k(true);
              return [
                {
                  ...s,
                  subscriberCount: s.subscriberCount + 1,
                  safeAmount: s.safeAmount + depositAmount,
                  safeSize: max(s.safeSize, s.safeAmount + depositAmount),
                },
              ];
          }
        },
      ];
    })
    // api: claim
    // input: proposed amount of periods to claim
    // output: true if claim was successful
    .define(() => {
      const claimAmount = (msg) => msg * periodAmount;
      const claimDelta = (msg) => msg * periodLength;
    })
    .api_(a.claim, (addr, msg) => {
      check(isSome(subscriptionM[addr]), "not subscribed");
      check(
        claimAmount(msg) <= fromSome(subscriptionM[addr], [0, 0])[0],
        "not enough remaining"
      );
      return [
        (k) => {
          const subscription = subscriptionM[addr];
          switch (subscription) {
            case None: // impossible
              k(false);
              return [s];
            case Some:
              const [remaining, lastTime] = subscription;
              enforce(
                thisConsensusTime() >= lastTime + claimDelta(msg),
                "not enough time has passed"
              );
              transfer([[claimAmount(msg), token]]).to(Provider); // (L2.3.3)
              subscriptionM[addr] = [
                remaining - claimAmount(msg),
                lastTime + claimDelta(msg),
              ];
              k(true);
              return [{ ...s, safeAmount: s.safeAmount - claimAmount(msg) }];
          }
        },
      ];
    })
    // api: cancel (L2.3.4)
    // input: nil
    // output: true if cancel was successful
    .api_(a.cancel, () => {
      check(isSome(subscriptionM[this]), "not subscribed");
      check(fromSome(subscriptionM[this], [0, 0])[0] > 0, "nothing to cancel");
      return [
        (k) => {
          const subscription = subscriptionM[this];
          switch (subscription) {
            case None: // impossible
              k(false);
              return [s];
            case Some:
              const [remaining, _] = subscription;
              transfer([[remaining, token]]).to(this); // (L2.3.4.1)
              subscriptionM[this] = [0, thisConsensusTime()]; // (L2.3.4.2)
              k(true);
              return [{ ...s, safeAmount: s.safeAmount - remaining }];
          }
        },
      ];
    });
  commit();
  exit();
});

/*
 * L3
 * L3.1 - Use existing ERC20 token ✅ (https://sepolia.etherscan.io/address/0x460cdd0daf5c0a47627089c13979acf9f00e3000)
 * L3.1.1 - Requires ethers ✅
 * L3.1.2 - Do NOT pay any tokens into reach contract ✅
 * L3.2 - Should only work on ETH network ✅
 * L3.2.1 - Exits if not on ETH network, i.e. ALGO ✅
 * L3.3 - Use ERC20 ABI ✅
 * L3.3.1 - allowance ✅
 * L3.3.2 - transferFrom ✅
 * L3.3.3 - See Jay session ✅
 * L3.4 - Emit events ✅
 * L3.4.1 - subscribe (join) ✅
 * L3.4.2 - claim ✅
 * L3.4.3 - cancel (withdraw) N/A
 * L3.B.1 - Deploy to TestNet ✅ (https://sepolia.etherscan.io/address/0x460cdd0daf5c0a47627089c13979acf9f00e3000)
 * L3.B.1.1 - Use GUI or script ✅
 * L3.B.1.2 - Use Solidity and Truffle to deploy ERC20 token ✅
 * L3.B.1.3 - Use own ERC20 token ✅ (https://sepolia.etherscan.io/address/0x460cdd0daf5c0a47627089c13979acf9f00e3000)
 * L3.B.1.4 - Confirm balances and allowances ✅
 */

export const L3 = Reach.App(() => {
  const [[Provider], [v], [a], [e], [State]] = L3Init();

  Provider.only(() => {
    const { token, periodCount, periodAmount, periodLength } = declassify(
      interact.getParams()
    );
  });
  Provider.publish(token, periodCount, periodAmount, periodLength).check(() => {
    check(periodCount > 0, "periodCount must be greater than 0");
    check(periodAmount > 0, "periodAmount must be greater than 0");
    check(periodLength > 0, "periodLength must be greater than 0");
  });
  Provider.interact.ready();

  const tokenObj = makeTokenObj(token);

  const subscriptionM = new Map(Tuple(UInt, UInt));

  const initialState = {
    subscriptionProvider: Provider, // constant, provider address
    token, // constant, token to claim
    periodCount, // constant, number of periods
    periodAmount, // constant, amount per period
    periodLength, // constant, period block time
    subscriberCount: 0, // variable, number of subscribers
    safeAmount: 0, // variable, current amount of tokens held for subscribers
    safeSize: 0, // variable, total amount of tokens received from subscribers
  };

  const [s] = parallelReduce([initialState])
    .while(true)
    .invariant(balance() == 0, "balance is accurate")
    /*
    .invariant(
      balance(token) == subscriptionM.reduce(0, (acc, w) => acc + w[0]),
      "token balance is accurate"
    )
    */
    .invariant(
      s.subscriberCount == subscriptionM.size(),
      "subscriber count is accurate"
    )
    .invariant(
      s.safeAmount == subscriptionM.reduce(0, (acc, w) => acc + w[0]),
      "safe amount is accurate"
    )
    .invariant(s.safeSize >= s.safeAmount, "safe size is accurate")
    .define(() => {
      v.state.set(() => State.fromObject(s));
      v.subscription.set((addr) => fromSome(subscriptionM[addr], [0, 0]));
    })
    .define(() => {
      const subscribeDepositAmount = periodAmount * periodCount;
      const subscribeNextState = {
        ...s,
        subscriberCount: s.subscriberCount + 1,
        safeAmount: s.safeAmount + subscribeDepositAmount,
        safeSize: max(s.safeSize, s.safeAmount + subscribeDepositAmount),
      };
    })
    // api: subscribe
    // input: nil
    // output: true if subscribe was successful
    // events: emits subscribe event
    // note:
    // it sets the allowance to the deposit amount outside of contract
    // needs to be done before calling subscribe and confirmed before
    // setting map
    .api_(a.subscribe, () => {
      check(isNone(subscriptionM[this]), "already subscribed");
      return [
        (k) => {
          const subscription = subscriptionM[this];
          switch (subscription) {
            case Some: // impossible
              k(false);
              return [s];
            case None: // new subscription
              subscriptionM[this] = [
                subscribeDepositAmount,
                thisConsensusTime(),
              ];
              k(true);
              e.join(this, token, periodAmount, periodCount, periodLength);
              return [subscribeNextState];
          }
        },
      ];
    })
    // api: claim
    // input: proposed amount of periods to claim
    // output: true if claim was successful
    .define(() => {
      const claimAmount = (msg) => msg * periodAmount;
      const claimDelta = (msg) => msg * periodLength;
      const claimNextState = (msg) => ({
        ...s,
        safeAmount: s.safeAmount - claimAmount(msg),
      });
    })
    .api_(a.claim, (addr, msg) => {
      check(isSome(subscriptionM[addr]), "not subscribed");
      check(
        claimAmount(msg) <= fromSome(subscriptionM[addr], [0, 0])[0],
        "not enough remaining"
      );
      return [
        (k) => {
          const subscription = subscriptionM[addr];
          switch (subscription) {
            case None: // impossible
              k(false);
              return [s];
            case Some:
              const [remaining, lastTime] = subscription;
              enforce(
                thisConsensusTime() >= lastTime + claimDelta(msg),
                "not enough time has passed"
              );
              // ---------------------------------
              // transfer
              // ---------------------------------
              const success = tokenObj.transferFrom(
                addr,
                Provider,
                claimAmount(msg)
              );
              enforce(success, "transfer failed");
              e.redeem(addr, Provider, claimAmount(msg));
              // ---------------------------------
              subscriptionM[addr] = [
                remaining - claimAmount(msg),
                lastTime + claimDelta(msg),
              ];
              k(success);
              return [claimNextState(msg)];
          }
        },
      ];
    });
  commit();
  exit();
});

/*
 * L4
 * N:M subscriptions using contract as escrow
 */
export const L4 = Reach.App(() => {
  const [[Provider], [v], [a], [e], [State]] = L4Init();

  Provider.only(() => {
    const { token } = declassify(interact.getParams());
  });
  Provider.publish(token);
  Provider.interact.ready();

  const providerM = new Map(UInt);
  const providerServiceM = new Map(Tuple(Address, UInt), ProviderService);
  const subscriptionM = new Map(Tuple(Address, UInt, Address), Subscription);

  const initialState = {
    token,
    providerCount: 0, // variable, number of providers
    subscriberCount: 0, // variable, number of subscribers
    safeAmount: 0, // variable, current amount of tokens held for subscribers
    safeSize: 0, // variable, total amount of tokens received from subscribers
  };

  const [s] = parallelReduce([initialState])
    .while(true)
    .invariant(balance() == 0, "balance is accurate")
    .invariant(
      balance(token) == subscriptionM.reduce(0, (acc, w) => acc + w[0]),
      "token balance is accurate"
    )
    .invariant(
      s.subscriberCount == subscriptionM.size(),
      "subscriber count is accurate"
    )
    .invariant(
      s.providerCount == providerM.size(),
      "provider count is accurate"
    )
    .invariant(
      s.safeAmount == subscriptionM.reduce(0, (acc, w) => acc + w[0]),
      "safe amount is accurate"
    )
    .invariant(s.safeSize >= s.safeAmount, "safe size is accurate")
    .paySpec([token])
    .define(() => {
      const getState = () => State.fromObject(s);
      v.state.set(getState);
      const getSubscription = (addr, i, addr2) => {
        const m_subscription = subscriptionM[[addr, i, addr2]];
        return fromSome(m_subscription, [0, 0]);
      };
      v.subscription.set(getSubscription);
    })
    // api: announce
    // input: provider service
    // output: true if announce was successful
    .api_(a.announce, (periodCount, periodAmount, periodLength) => {
      check(isNone(providerM[this]) || isSome(providerM[this]), "impossible");
      return [
        (k) => {
          const i = providerM[this];
          switch (i) {
            case None: {
              const providerService = ProviderService.fromObject({
                periodCount,
                periodAmount,
                periodLength,
                subscriberCount: 0,
              });
              providerServiceM[[this, 0]] = providerService;
              providerM[this] = 1;
              e.announcement(this, 0, periodCount, periodAmount, periodLength);
              k(true);
              return [{ ...s, providerCount: s.providerCount + 1 }];
            }
            case Some: {
              // impossible
              const providerService = ProviderService.fromObject({
                periodCount,
                periodAmount,
                periodLength,
                subscriberCount: 0,
              });
              providerServiceM[[this, i]] = providerService;
              providerM[this] = i + 1;
              e.announcement(this, i, periodCount, periodAmount, periodLength);
              k(true);
              return [s];
            }
          }
        },
      ];
    })
    // api: subscribe
    // input: nil
    // output: true if subscribe was successful
    .define(() => {
      const depositAmount = (addr, i) => {
        const ps = providerServiceM[[addr, i]];
        switch (ps) {
          case None:
            return 0;
          case Some:
            const { periodCount, periodAmount } = ps;
            return periodAmount * periodCount;
        }
      };
    })
    .api_(a.subscribe, (addr, i) => {
      check(isNone(subscriptionM[[addr, i, this]]), "already subscribed");
      check(isSome(providerServiceM[[addr, i]]), "invalid provider");
      return [
        [0, [depositAmount(addr, i), token]],
        (k) => {
          subscriptionM[[addr, i, this]] = [
            depositAmount(addr, i),
            thisConsensusTime(),
          ];
          e.join(addr, i, this);
          k(true);
          return [
            {
              ...s,
              subscriberCount: s.subscriberCount + 1,
              safeAmount: s.safeAmount + depositAmount(addr, i),
              safeSize: max(s.safeSize, s.safeAmount + depositAmount(addr, i)),
            },
          ];
        },
      ];
    })
    // api: claim
    // input: proposed amount of periods to claim
    // output: true if claim was successful
    .define(() => {
      const claimAmount = (addr, i, msg) =>
        maybe(providerServiceM[[addr, i]], 0, (ps) => {
          const { periodAmount } = ps;
          return periodAmount * msg;
        });
      const claimDelta = (addr, i, msg) =>
        maybe(providerServiceM[[addr, i]], 0, (ps) => {
          const { periodLength } = ps;
          return msg * periodLength;
        });
    })
    .api_(a.claim, (addr, i, addr2, msg) => {
      check(isSome(subscriptionM[[addr, i, addr2]]), "not subscribed");
      check(
        claimAmount(addr, i, msg) <= getSubscription(addr, i, addr2)[0],
        "not enough remaining"
      );
      return [
        (k) => {
          const [remaining, lastTime] = getSubscription(addr, i, addr2);
          enforce(
            thisConsensusTime() >= lastTime + claimDelta(addr, i, msg),
            "not enough time has passed"
          );
          transfer([[claimAmount(addr, i, msg), token]]).to(addr); // (L2.3.3)
          subscriptionM[[addr, i, addr2]] = [
            remaining - claimAmount(addr, i, msg),
            lastTime + claimDelta(addr, i, msg),
          ];
          e.redeem(addr, i, addr2, msg);
          k(true);
          return [
            { ...s, safeAmount: s.safeAmount - claimAmount(addr, i, msg) },
          ];
        },
      ];
    })
    // api: cancel (L2.3.4)
    // input: nil
    // output: true if cancel was successful
    .api_(a.cancel, (addr, i) => {
      check(isSome(subscriptionM[[addr, i, this]]), "not subscribed");
      check(getSubscription(addr, i, this)[0] > 0, "nothing to cancel");
      return [
        (k) => {
          const subscription = getSubscription(addr, i, this);
          const [remaining, _] = subscription;
          transfer([[remaining, token]]).to(this); // (L2.3.4.1)
          subscriptionM[[addr, i, this]] = [0, thisConsensusTime()]; // (L2.3.4.2)
          k(true);
          return [{ ...s, safeAmount: s.safeAmount - remaining }];
        },
      ];
    });
  commit();
  exit();
});

/*
 * L5
 * N:M subscription service using ERC20 abi
 */
export const L5 = Reach.App(() => {
  const [[Provider], [v], [a], [e], [State]] = L5Init();
  
  Provider.only(() => {
    const { token } = declassify(interact.getParams());
  });
  Provider.publish(token);
  Provider.interact.ready();

  const tokenObj = makeTokenObj(token);

  const providerM = new Map(UInt);
  const providerServiceM = new Map(Tuple(Address, UInt), ProviderService);
  const subscriptionM = new Map(Tuple(Address, UInt, Address), Subscription);

  const initialState = {
    token,
    providerCount: 0, // variable, number of providers
    subscriberCount: 0, // variable, number of subscribers
    safeAmount: 0, // variable, current amount of tokens held for subscribers
    safeSize: 0, // variable, total amount of tokens received from subscribers
  };

  const [s] = parallelReduce([initialState])
    .while(true)
    .invariant(balance() == 0, "balance is accurate")
    .invariant(
      s.subscriberCount == subscriptionM.size(),
      "subscriber count is accurate"
    )
    .invariant(
      s.providerCount == providerM.size(),
      "provider count is accurate"
    )
    .invariant(
      s.safeAmount == subscriptionM.reduce(0, (acc, w) => acc + w[0]),
      "safe amount is accurate"
    )
    .define(() => {
      const getState = () => State.fromObject(s);
      v.state.set(getState);
      const getSubscription = (addr, i, addr2) => {
        const m_subscription = subscriptionM[[addr, i, addr2]];
        return fromSome(m_subscription, [0, 0]);
      };
      v.subscription.set(getSubscription);
    })
    // api: announce
    // input: provider service
    // output: true if announce was successful
    .api_(a.announce, (periodCount, periodAmount, periodLength) => {
      check(isNone(providerM[this]) || isSome(providerM[this]), "impossible");
      return [
        (k) => {
          const i = providerM[this];
          switch (i) {
            case None: {
              const providerService = ProviderService.fromObject({
                periodCount,
                periodAmount,
                periodLength,
                subscriberCount: 0,
              });
              providerServiceM[[this, 0]] = providerService;
              providerM[this] = 1;
              e.announcement(this, 0, periodCount, periodAmount, periodLength);
              k(true);
              return [{ ...s, providerCount: s.providerCount + 1 }];
            }
            case Some: {
              // impossible
              const providerService = ProviderService.fromObject({
                periodCount,
                periodAmount,
                periodLength,
                subscriberCount: 0,
              });
              providerServiceM[[this, i]] = providerService;
              providerM[this] = i + 1;
              e.announcement(this, i, periodCount, periodAmount, periodLength);
              k(true);
              return [s];
            }
          }
        },
      ];
    })
    // api: subscribe
    // input: nil
    // output: true if subscribe was successful
    // events: emits join event
    // note:
    // it sets the allowance to the deposit amount outside of contract
    // needs to be done before calling subscribe and confirmed before
    // setting map
    .define(() => {
      const depositAmount = (addr, i) => {
        const ps = providerServiceM[[addr, i]];
        switch (ps) {
          case None:
            return 0;
          case Some:
            const { periodCount, periodAmount } = ps;
            return periodAmount * periodCount;
        }
      };
    })
    .api_(a.subscribe, (addr, i) => {
      check(isNone(subscriptionM[[addr, i, this]]), "already subscribed");
      check(isSome(providerServiceM[[addr, i]]), "invalid provider");
      return [
        (k) => {
          subscriptionM[[addr, i, this]] = [
            depositAmount(addr, i),
            thisConsensusTime(),
          ];
          e.join(addr, i, this);
          k(true);
          return [
            {
              ...s,
              subscriberCount: s.subscriberCount + 1,
              safeAmount: s.safeAmount + depositAmount(addr, i),
              safeSize: max(s.safeSize, s.safeAmount + depositAmount(addr, i)),
            },
          ];
        },
      ];
    })
    // api: claim
    // input: proposed amount of periods to claim
    // output: true if claim was successful
    .define(() => {
      const claimAmount = (addr, i, msg) =>
        maybe(providerServiceM[[addr, i]], 0, (ps) => {
          const { periodAmount } = ps;
          return periodAmount * msg;
        });
      const claimDelta = (addr, i, msg) =>
        maybe(providerServiceM[[addr, i]], 0, (ps) => {
          const { periodLength } = ps;
          return msg * periodLength;
        });
    })
    .api_(a.claim, (addr, i, addr2, msg) => {
      check(isSome(subscriptionM[[addr, i, addr2]]), "not subscribed");
      check(
        claimAmount(addr, i, msg) <= getSubscription(addr, i, addr2)[0],
        "not enough remaining"
      );
      return [
        (k) => {
          const [remaining, lastTime] = getSubscription(addr, i, addr2);
          enforce(
            thisConsensusTime() >= lastTime + claimDelta(addr, i, msg),
            "not enough time has passed"
          );
          // ---------------------------------
          // transfer from subscriber to provider
          // ---------------------------------
          const success = tokenObj.transferFrom(
            addr, // subscriber
            addr2, // provider
            claimAmount(addr, i, msg)
          );
          enforce(success, "transfer failed");
          // ---------------------------------
          subscriptionM[[addr, i, addr2]] = [
            remaining - claimAmount(addr, i, msg),
            lastTime + claimDelta(addr, i, msg),
          ];
          e.redeem(addr, i, addr2, msg);
          k(true);
          return [
            { ...s, safeAmount: s.safeAmount - claimAmount(addr, i, msg) },
          ];
        },
      ];
    });
  commit();
  exit();
});

export const main = L3;
