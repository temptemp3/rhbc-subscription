"reach 0.1";
/*
 * L1.1 Setup and scaffold
 * L1.2 Use 2 particpants
 * L1.2.1 Deployer
 * L1.1.1.1 Sets perameters such as length and amount of each payment
 * L1.2.2 Attacher
 * L1.2.2.1 If attacher accepts they should pay large amount into contract
 * L1.2.2.2 If attacher rejects exit
 * L1.3 The contract should pay out regular amount, subscription fee, to the Deployer
 * L1.4 Display status messages
 * L1.4.1 Show balance before contract
 * L1.4.2 Output boolean that Attacher accepts the terms or not
 * L1.4.3 Log activity
 * L1.4.4 Show balance after contract
 */
const BaseDetails = Object({
  periodCount: UInt, // how many payments, ex 12
  periodAmount: UInt, // how much each payment, ex 100
  periodLength: UInt, // how long each payment, ex 30 days in blocks
});
const L1DetailsExtensions = Object({
  token: Token, // ERC20 but need it as Token to satisfy (L1.2.2.1)
  ttl: UInt, // time to live
});
const L1Details = Object({
  ...Object.fields(BaseDetails),
  ...Object.fields(L1DetailsExtensions),
});
const L1Params = Object({
  ...Object.fields(L1Details),
});
const fReady = Fun([], Null);
const fGetParams = (Params) => Fun([], Params);
const fClaim = Fun([UInt], Bool);
const hasReady = {
  ready: fReady,
};
const Participants = (Params) => [
  // Participant: Deployer (Provider)
  Participant("Deployer", {
    ...hasReady,
    getParams: fGetParams(Params),
  }),
];
const L1Participants = () => [
  // Participant: Attacher (Subscriber)
  Participant("Attacher", {
    ...hasReady,
    accept: Fun([], Bool),
  }),
];
const api = {
  claim: fClaim,
};
export const L1 = Reach.App(() => {
  setOptions({
    connectors: [ETH],
  });
  const [Provider, Subscriber] = [
    ...Participants(L1Params),
    ...L1Participants(),
  ];
  const [a] = [API(api)];
  init();
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
 * L2.3.5 Script display
 * L2.3.5.1 Account balances
 * L2.3.5.2 Withdrawal message
 * L2.3.5.3 Claim message
 * L2.3.5.4 Final outcome
 */
const max = (a, b) => (a > b ? a : b);
const fClaim2 = Fun([Address, UInt], Bool);
const fSubscribe = Fun([], Bool);
const fCancel = Fun([], Bool);
const api2 = {
  ...api,
  claim: fClaim2,
  subscribe: fSubscribe,
  cancel: fCancel,
};
const BaseState = Struct([
  ["subscriptionProvider", Address],
  ["periodCount", UInt],
  ["periodAmount", UInt],
  ["periodLength", UInt],
  ["subscriberCount", UInt],
  ["safeAmount", UInt],
]);
const L2StateExtension = Struct([["token", Token]]);
const L2State = Struct([
  ...Struct.fields(BaseState),
  ...Struct.fields(L2StateExtension),
]);
const L2DetaillsExtensions = Object({
  token: Token,
});
const L2Details = Object({
  ...Object.fields(BaseDetails),
  ...Object.fields(L2DetaillsExtensions),
});
const L2Params = Object({
  ...Object.fields(L2Details),
});
const view = {
  state: Fun([], L2State),
  subscription: Fun([Address], Tuple(UInt, UInt)),
};
export const L2 = Reach.App(() => {
  // one to many subscriptions
  setOptions({
    connectors: [ETH],
  });
  const [Provider] = Participants(L2Params);
  const [a] = [API(api2)];
  const [v] = [View(view)];
  init();
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
      v.state.set(() => L2State.fromObject(s));
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
const L3StateExtension = Struct([["token", Contract]]);
const L3State = Struct([
  ...Struct.fields(BaseState),
  ...Struct.fields(L3StateExtension),
]);
const L3DetailExtension = Object({
  token: Contract,
});
const L3Details = Object({
  ...Object.fields(BaseDetails),
  ...Object.fields(L3DetailExtension),
});
const L3Params = Object({
  ...Object.fields(L3Details),
});
const l3View = {
  ...view,
  state: Fun([], L3State),
};
const api3 = {
  ...api,
  claim: fClaim2,
  subscribe: fSubscribe,
};
const Event = () => [
  Events({
    join: [Address, Contract, UInt, UInt, UInt],
    redeem: [Address, Address, UInt],
  }),
];
export const L3 = Reach.App(() => {
  // one to many subscriptions
  setOptions({
    connectors: [ETH],
  });
  const [Provider] = Participants(L3Params);
  const [a] = [API(api2)];
  const [v] = [View(l3View)];
  const [e] = Event();
  init();
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

  const tokenObj = remote(token, {
    transferFrom: Fun([Address, Address, UInt], Bool),
    allowance: Fun([Address, Address], UInt),
  });

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
      v.state.set(() => L3State.fromObject(s));
      v.subscription.set((addr) => fromSome(subscriptionM[addr], [0, 0]));
    })
    .define(() => {
      const subscribeDepositAmount = periodAmount * periodCount;
      const subscribeNextState = {
        ...s,
        subscriberCount: s.subscriberCount + 1,
        safeAmount: s.safeAmount + subscribeDepositAmount,
        safeSize: max(s.safeSize, s.safeAmount + subscribeDepositAmount)
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
              subscriptionM[this] = [subscribeDepositAmount, thisConsensusTime()];
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
      })
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
    })
    // api: cancel (L2.3.4)
    // input: nil
    // output: true if cancel was successful
    .api_(a.cancel, () => {
      return [
        (k) => {
          k(true);
          return [s];
        },
      ];
    });
  /*
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
              //transfer([[remaining, token]]).to(this); // (L2.3.4.1)
              // set allowance to 0
              subscriptionM[this] = [0, thisConsensusTime()]; // (L2.3.4.2)
              k(true);
              return [{ ...s, safeAmount: s.safeAmount - remaining }];
          }
        },
      ];
    });
    */
  commit();
  exit();
});

export const main = L3;
