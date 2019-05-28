Exor Core integration/staging repository
=====================================

Exor is an open source crypto-currency focused on fast private transactions with low transaction fees & environmental footprint. It utilizes a custom Proof of Stake protocol for securing its network that rewards masternodes with 80% of the block reward while stakers take the remaining 20%. The goal of Exor is to achieve a decentralized sustainable crypto currency with near instant full-time private transactions, fair governance and community intelligence.

Exor was originally designed to be used as a payment vehicle for different projects in the Exor ecosystem. The first main project that will interface with and utilize the EXOR network is the Crypto Asset Manager software and is currently available to masternode holders only.

More information at [exor.io](https://exor.io)

### Coin Specs
<table>
<tr><td>Consensus</td><td>Proof-of-Stake (PoS)</td></tr>
<tr><td>Block Time</td><td>60 Seconds</td></tr>
<tr><td>Difficulty Retargeting</td><td>60 Seconds</td></tr>
<tr><td>Port</td><td>51572</td></tr>
<tr><td>RPC Port</td><td>51573</td></tr>
<tr><td>Masternode Collateral</td><td>50,000 EXOR</td></tr>
<tr><td>Masternode Activation</td><td>Block 10281</td></tr>
<tr><td>Min Stake Age</td><td>60 Minutes</td></tr>
<tr><td>Maturity</td><td>100 Confirmations</td></tr>
<tr><td>Max Coin Supply</td><td>70,196,357.44 EXOR*</td></tr>
<tr><td>Premine</td><td>54,999,979.84 EXOR*</td></tr>
</table>

*The 54,999,979.84 pre-mine was minted to adequately cover swapping early investors from the NLX blockchain. Once the swap is complete, a large number of unswapped coins will be publicly burned and the total supply adjusted accordingly.

### PoS Rewards Breakdown

After the "pre-mine" and "fair launch" phases, the remaining phases are set to reduce block rewards by 15% every year on average.

<table>
<th>Phase</th><th>Block Height</th><th>Block Reward</th><th>Stake Reward</th><th>Masternode Reward</th>
<tr><td>Pre-mine</td><td>1-200</td><td>274999.8992 EXOR</td><td>0% (0 EXOR)</td><td>0% (0 EXOR)</td></tr>
<tr><td>Fair Launch</td><td>201-20360</td><td>0.001 EXOR</td><td>20% (0.0002 EXOR)*</td><td>80% (0.0008 EXOR)*</td></tr>
<tr><td>Year 1</td><td>20361-545960</td><td>5.4 EXOR</td><td>20% (1.08 EXOR)</td><td>80% (4.32 EXOR)</td></tr>
<tr><td>Year 2</td><td>545961-1071560</td><td>4.59 EXOR</td><td>20% (0.918 EXOR)</td><td>80% (3.672 EXOR)</td></tr>
<tr><td>Year 3</td><td>1071561-1597160</td><td>3.9015 EXOR</td><td>20% (0.7803 EXOR)</td><td>80% (3.1212 EXOR)</td></tr>
<tr><td>Year 4</td><td>1597161-2122760</td><td>3.3163 EXOR</td><td>20% (0.6633 EXOR)</td><td>80% (2.653 EXOR)</td></tr>
<tr><td>Year 5</td><td>2122761-2648360</td><td>2.8188 EXOR</td><td>20% (0.5638 EXOR)</td><td>80% (2.2551 EXOR)</td></tr>
<tr><td>Year 6</td><td>2648361-3173960</td><td>2.3960 EXOR</td><td>20% (0.4792 EXOR)</td><td>80% (1.9168 EXOR)</td></tr>
<tr><td>Year 7</td><td>3173961-3699560</td><td>2.0366 EXOR</td><td>20% (0.4073 EXOR)</td><td>80% (1.6293 EXOR)</td></tr>
<tr><td>Year 8</td><td>3699561-4225160</td><td>1.7311 EXOR</td><td>20% (0.3462 EXOR)</td><td>80% (1.3849 EXOR)</td></tr>
<tr><td>Year 9</td><td>4225161-4750760</td><td>1.4714 EXOR</td><td>20% (0.2943 EXOR)</td><td>80% (1.1772 EXOR)</td></tr>
<tr><td>Year 10</td><td>4750761-5276360</td><td>1.2507 EXOR</td><td>20% (0.2501 EXOR)</td><td>80% (1.0006 EXOR)</td></tr>
</table>

*Masternodes do not receive any rewards until block 10281 to give ample setup time. Stakers will take the full block reward between blocks 201-10280 as a result.
