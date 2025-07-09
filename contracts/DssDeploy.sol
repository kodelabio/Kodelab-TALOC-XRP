// SPDX-License-Identifier: Proprietary
//
// © 2024 Kodelab. All rights reserved.
// This smart contract code is developed and owned by Kodelab and provided to Taloc for deployment and use under the terms agreed upon with Kodelab.
// Unauthorized use, reproduction, modification, or distribution of this code by parties other than Taloc is strictly prohibited.
// Kodelab assumes no liability for any misuse, unintended outcomes, or errors arising from alterations made by third parties.
// For inquiries or further information, visit Kodelab at https://kodelab.io.


pragma solidity ^0.8.20;

import {DSAuth, DSAuthority}  from "./lib/ds-auth/auth.sol";
import {DSPause}              from "./ds-pause/pause.sol";
import {Vat}                  from "./dss/taloc.sol";
import {Jug}                  from "./dss/jug.sol";
import {Vow}                  from "./dss/vow.sol";
import {Cat}                  from "./dss/cat.sol";
import {DaiJoin}             from "./dss/join.sol";
import {Flapper}             from "./dss/flap.sol";
import {Flopper}             from "./dss/flop.sol";
import {Flipper}             from "./dss/flip.sol";
import {Dai}                 from "./dss/dai.sol";
import {End}                 from "./dss/end.sol";
import {ESM}                 from "./esm/ESM.sol";
import {Pot}                 from "./dss/pot.sol";
import {Spotter}             from "./dss/spot.sol";
import {TalocClient}         from "./taloc/TalocClient.sol";
import {Pool}                from "./taloc/Pool.sol";
import {Asset}               from "./ds-asset/Asset.sol";

contract VatFab     { function newVat()                     external returns (Vat v)        { v=new Vat();        v.rely(msg.sender); v.deny(address(this)); } }
contract JugFab     { function newJug(address vat)          external returns (Jug j)        { j=new Jug(vat);     j.rely(msg.sender); j.deny(address(this)); } }
contract VowFab     { function newVow(address vat,address f,address p) external returns(Vow v){ v=new Vow(vat,f,p);v.rely(msg.sender); v.deny(address(this)); } }
contract CatFab     { function newCat(address vat)          external returns (Cat c)        { c=new Cat(vat);     c.rely(msg.sender); c.deny(address(this)); } }
contract DaiFab     { function newDai(uint256 cid)          external returns (Dai d)        { d=new Dai(cid);     d.rely(msg.sender); d.deny(address(this)); } }
contract DaiJoinFab { function newDaiJoin(address v,address d) external returns (DaiJoin j){ j=new DaiJoin(v,d); } }
contract FlapFab    { function newFlap(address v,address g) external returns (Flapper f)    { f=new Flapper(v,g); f.rely(msg.sender); f.deny(address(this)); } }
contract FlopFab    { function newFlop(address v,address g) external returns (Flopper p)    { p=new Flopper(v,g); p.rely(msg.sender); p.deny(address(this)); } }
contract FlipFab    { function newFlip(address v,address c,bytes32 i) external returns(Flipper f){ f=new Flipper(v,c,i);f.rely(msg.sender);f.deny(address(this)); } }
contract SpotFab    { function newSpotter(address v)        external returns (Spotter s)    { s=new Spotter(v);   s.rely(msg.sender); s.deny(address(this)); } }
contract PotFab     { function newPot(address v)            external returns (Pot p)        { p=new Pot(v);       p.rely(msg.sender); p.deny(address(this)); } }
contract EndFab     { function newEnd()                     external returns (End e)        { e=new End();        e.rely(msg.sender); e.deny(address(this)); } }
contract ESMFab     { function newESM(address g,address e,address pit,uint256 m) external returns (ESM s){ s=new ESM(g,e,pit,m);} }
contract PauseFab   { function newPause(uint256 d,address o,address a) external returns (DSPause p){ p=new DSPause(d,o,a);} }
contract TalocClientFab { function newTalocClient() external returns (TalocClient c){ c=new TalocClient(); } }
contract PoolFab        { function newPool(address e,address c)  external returns (Pool p){ p=new Pool(e,c);} }
contract AssetFab       { function newAsset(address o)           external returns (Asset a){ a=new Asset(o);} }

contract DssDeploy is DSAuth {
    VatFab     public immutable vatFab;
    JugFab     public immutable jugFab;
    VowFab     public immutable vowFab;
    CatFab     public immutable catFab;
    DaiFab     public immutable daiFab;
    DaiJoinFab public immutable daiJoinFab;
    FlapFab    public immutable flapFab;
    FlopFab    public immutable flopFab;
    FlipFab    public immutable flipFab;
    SpotFab    public immutable spotFab;
    PotFab     public immutable potFab;
    EndFab     public immutable endFab;
    ESMFab     public immutable esmFab;
    PauseFab   public immutable pauseFab;
    TalocClientFab public immutable talocClientFab;
    PoolFab        public immutable poolFab;
    AssetFab       public immutable assetFab;

    Vat     public taloc;
    Jug     public jug;
    Vow     public vow;
    Cat     public cat;
    Dai     public dai;
    DaiJoin public daiJoin;
    Flapper public flap;
    Flopper public flop;
    Spotter public spotter;
    Pot     public pot;
    End     public end;
    ESM     public esm;
    DSPause public pause;
    TalocClient public talocClient;
    Pool        public pool;

    struct Ilk { Flipper flip; address join; address token; }
    mapping(bytes32=>Ilk) public ilks;
    Asset[] public nftCollaterals;

    constructor(
        VatFab _vatFab, JugFab _jugFab, VowFab _vowFab, CatFab _catFab, DaiFab _daiFab, DaiJoinFab _daiJoinFab,
        FlapFab _flapFab, FlopFab _flopFab, FlipFab _flipFab, SpotFab _spotFab, PotFab _potFab, EndFab _endFab,
        ESMFab _esmFab, PauseFab _pauseFab, TalocClientFab _talocClientFab, PoolFab _poolFab, AssetFab _assetFab
    ) {
        vatFab=_vatFab;jugFab=_jugFab;vowFab=_vowFab;catFab=_catFab;daiFab=_daiFab;daiJoinFab=_daiJoinFab;
        flapFab=_flapFab;flopFab=_flopFab;flipFab=_flipFab;spotFab=_spotFab;potFab=_potFab;endFab=_endFab;
        esmFab=_esmFab;pauseFab=_pauseFab;talocClientFab=_talocClientFab;poolFab=_poolFab;assetFab=_assetFab;
    }

    function rad(uint256 wad) internal pure returns(uint256){return wad*1e27;}

    function deployVat() external auth {
        require(address(taloc)==address(0));
        taloc=vatFab.newVat();
        spotter=spotFab.newSpotter(address(taloc));
        taloc.rely(address(spotter));
    }

    function deployDai(uint256 chainId) external auth {
        require(address(taloc)!=address(0));
        dai=daiFab.newDai(chainId);
        daiJoin=daiJoinFab.newDaiJoin(address(taloc),address(dai));
        dai.rely(address(daiJoin));
    }

    function deployTaxation() external auth {
        require(address(dai)!=address(0));
        jug=jugFab.newJug(address(taloc));
        pot=potFab.newPot(address(taloc));
        taloc.rely(address(jug));
        taloc.rely(address(pot));
    }

    function deployAuctions(address gov) external auth {
        require(address(jug)!=address(0));
        flap=flapFab.newFlap(address(taloc),gov);
        flop=flopFab.newFlop(address(taloc),gov);
        vow=vowFab.newVow(address(taloc),address(flap),address(flop));
        jug.file("vow",address(vow));
        pot.file("vow",address(vow));
        taloc.rely(address(flop));
        flap.rely(address(vow));
        flop.rely(address(vow));
    }

    function deployLiquidator() external auth {
        require(address(vow)!=address(0));
        cat=catFab.newCat(address(taloc));
        cat.file("vow",address(vow));
        taloc.rely(address(cat));
        vow.rely(address(cat));
    }

    function deployShutdown(address gov,address pit,uint256 min) external auth {
        require(address(cat)!=address(0));
        end=endFab.newEnd();
        end.file("taloc",address(taloc));
        end.file("cat",address(cat));
        end.file("vow",address(vow));
        end.file("pot",address(pot));
        end.file("spot",address(spotter));
        taloc.rely(address(end));
        cat.rely(address(end));
        vow.rely(address(end));
        pot.rely(address(end));
        spotter.rely(address(end));
        esm=esmFab.newESM(gov,address(end),pit,min);
        end.rely(address(esm));
    }

    function deployPause(uint256 delay,address authority) public virtual auth {
        require(address(end)!=address(0));
        pause=pauseFab.newPause(delay,address(0),authority);
        address p=address(pause.proxy());
        taloc.rely(p);cat.rely(p);vow.rely(p);jug.rely(p);pot.rely(p);spotter.rely(p);flap.rely(p);flop.rely(p);end.rely(p);
        if(address(talocClient)!=address(0)) talocClient.transferOwnership(p);
        if(address(pool)!=address(0)) pool.transferOwnership(p);
        for(uint256 i=0;i<nftCollaterals.length;i++){
            if(nftCollaterals[i].owner()==address(this)) nftCollaterals[i].transferOwnership(p);
        }
    }

    function deployCollateral(bytes32 ilk,address join,address pip) external auth {
        require(ilk!=bytes32(0)&&join!=address(0)&&pip!=address(0));
        require(address(pause)!=address(0));
        Flipper f=flipFab.newFlip(address(taloc),address(cat),ilk);
        ilks[ilk]=Ilk(f,join,address(0));
        spotter.file(ilk,"pip",pip);
        cat.file(ilk,"flip",address(f));
        taloc.init(ilk);
        jug.init(ilk);
        taloc.rely(join);
        cat.rely(address(f));
        f.rely(address(cat));
        f.rely(address(end));
        f.rely(address(pause.proxy()));
    }

    function releaseAuth() external auth {
        address self=address(this);
        taloc.deny(self);cat.deny(self);vow.deny(self);jug.deny(self);pot.deny(self);dai.deny(self);
        spotter.deny(self);flap.deny(self);flop.deny(self);end.deny(self);
    }

    function deployTaloc(address reg,uint256 rate) external auth {
        require(address(dai)!=address(0));
        talocClient=talocClientFab.newTalocClient();
        pool=poolFab.newPool(address(dai),address(talocClient));
        talocClient.initialize(address(dai),address(pool),reg,rate);
    }

    function releaseAuthTaloc() external auth {
        if(address(talocClient)!=address(0)) talocClient.transferOwnership(address(0));
        if(address(pool)!=address(0)) pool.transferOwnership(address(0));
    }

    function deployNFTCollateral(
        bytes32 ilk,
        string memory name,
        string memory symbol,
        address pip,
        address bootstrapTo,
        string memory uri
    ) external auth {
        require(ilk!=bytes32(0));
        require(address(talocClient)!=address(0));
        require(ilks[ilk].token==address(0));
        Asset a=assetFab.newAsset(address(this));
        a.initialize(name,symbol);
        if(bootstrapTo!=address(0)) a.safeMint(bootstrapTo,uri);
        talocClient.whitelistToken(address(a),0);
        ilks[ilk].token=address(a);
        if(pip!=address(0)&&address(spotter)!=address(0)) spotter.file(ilk,"pip",pip);
        nftCollaterals.push(a);
    }
}