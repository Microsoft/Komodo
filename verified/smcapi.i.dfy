include "smcapi.s.dfy"

//=============================================================================
// Hoare Specification of Monitor Calls
//=============================================================================
function smc_initAddrspace_premium(pageDbIn: PageDb, addrspacePage: PageNr,
    l1PTPage: PageNr) : (PageDb, int) // PageDbOut, KEV_ERR
    requires validPageDb(pageDbIn);
    ensures  validPageDb(smc_initAddrspace_premium(pageDbIn, addrspacePage, l1PTPage).0);
{
    initAddrspacePreservesPageDBValidity(pageDbIn, addrspacePage, l1PTPage);
    smc_initAddrspace(pageDbIn, addrspacePage, l1PTPage)
}

function smc_initDispatcher_premium(pageDbIn: PageDb, page:PageNr, addrspacePage:PageNr,
    entrypoint:int) : (PageDb, int) // PageDbOut, KEV_ERR
    requires validPageDb(pageDbIn);
    ensures  validPageDb(smc_initDispatcher_premium(pageDbIn, page, addrspacePage, entrypoint).0);
{
    smc_initDispatcher(pageDbIn, page, addrspacePage, entrypoint)
}

function smc_initL2PTable_premium(pageDbIn: PageDb, page: PageNr,
    addrspacePage: PageNr, l1index: int) : (PageDb, int)
    requires validPageDb(pageDbIn)
    ensures validPageDb(smc_initL2PTable_premium(pageDbIn, page, addrspacePage, l1index).0)
{
    smc_initL2PTable(pageDbIn, page, addrspacePage, l1index)
}

function smc_remove_premium(pageDbIn: PageDb, page: PageNr) : (PageDb, int) // PageDbOut, KEV_ERR
    requires validPageDb(pageDbIn)
    ensures  validPageDb(smc_remove_premium(pageDbIn, page).0)
{
    removePreservesPageDBValidity(pageDbIn, page);
    smc_remove(pageDbIn, page)
}

function smc_mapSecure_premium(pageDbIn: PageDb, page: PageNr, addrspacePage: PageNr,
    mapping: Mapping, physPage: int) : (PageDb, int) // PageDbOut, KEV_ERR
    requires validPageDb(pageDbIn)
    ensures  validPageDb(smc_mapSecure_premium(pageDbIn, page, addrspacePage, mapping, physPage).0)
{
    mapSecurePreservesPageDBValidity(pageDbIn, page, addrspacePage, mapping, physPage);
    smc_mapSecure(pageDbIn, page, addrspacePage, mapping, physPage)
}

function smc_mapInsecure_premium(pageDbIn: PageDb, addrspacePage: PageNr,
    physPage: int, mapping : Mapping) : (PageDb, int)
    requires validPageDb(pageDbIn)
    ensures  validPageDb(smc_mapInsecure_premium(pageDbIn, addrspacePage, physPage, mapping).0)
{
    mapInsecurePreservesPageDbValidity(pageDbIn, addrspacePage, physPage, mapping);
    smc_mapInsecure(pageDbIn, addrspacePage, physPage, mapping)
}

function smc_finalise_premium(pageDbIn: PageDb, addrspacePage: PageNr) : (PageDb, int)
    requires validPageDb(pageDbIn)
    ensures  validPageDb(smc_finalise_premium(pageDbIn, addrspacePage).0)
{
    finalisePreservesPageDbValidity(pageDbIn, addrspacePage);
    smc_finalise(pageDbIn, addrspacePage)
}

function smc_enter_premium(pageDbIn: PageDb, dispPage: PageNr, arg1: int, arg2: int, arg3: int)
    : (PageDb, int)
    requires validPageDb(pageDbIn) 
    ensures validPageDb(smc_enter_premium(pageDbIn, dispPage, arg1, arg2, arg3).0)
{
    enterPreservesPageDbValidity(pageDbIn, dispPage, arg1, arg2, arg3);
    smc_enter(pageDbIn, dispPage, arg1, arg2, arg3)
}

function smc_resume_premium(pageDbIn: PageDb, dispPage: PageNr)
    : (PageDb, int)
    requires validPageDb(pageDbIn) 
    ensures validPageDb(smc_resume_premium(pageDbIn, dispPage).0)
{
    resumePreservesPageDbValidity(pageDbIn, dispPage);
    smc_resume(pageDbIn, dispPage)
}

function smc_stop_premium(pageDbIn: PageDb, addrspacePage: PageNr)
    : (PageDb, int)
    requires validPageDb(pageDbIn)
    ensures  validPageDb(smc_stop_premium(pageDbIn, addrspacePage).0)
{
    stopPreservesPageDbValidity(pageDbIn, addrspacePage);
    smc_stop(pageDbIn, addrspacePage)
}

function smchandler_premium(pageDbIn: PageDb, callno: int, arg1: int, arg2: int,
    arg3: int, arg4: int) : (PageDb, int, int) // pageDbOut, err, val
    requires validPageDb(pageDbIn)
    ensures validPageDb(smchandler_premium(pageDbIn, callno, arg1, arg2, arg3, arg4).0)
{
    smchandlerPreservesPageDbValidity(pageDbIn, callno, arg1, arg2, arg3, arg4);
    smchandler(pageDbIn, callno, arg1, arg2, arg3, arg4)
}

//=============================================================================
// Properties of Monitor Calls
//=============================================================================

//-----------------------------------------------------------------------------
// PageDb Validity Preservation
//-----------------------------------------------------------------------------
lemma initAddrspacePreservesPageDBValidity(pageDbIn : PageDb,
    addrspacePage : PageNr, l1PTPage : PageNr)
    requires validPageDb(pageDbIn)
    ensures validPageDb(smc_initAddrspace(pageDbIn, addrspacePage, l1PTPage).0)
{
    reveal_validPageDb();
     var pageDbOut := smc_initAddrspace(pageDbIn, addrspacePage, l1PTPage).0;
     var errOut := smc_initAddrspace(pageDbIn, addrspacePage, l1PTPage).1;

     if( errOut != KEV_ERR_SUCCESS() ) {
        // The error case is trivial because PageDbOut == PageDbIn
     } else {
         // Necessary semi-manual proof of validPageDbEntry(pageDbOut, l1PTPage)
         // The interesting part of the proof deals with the contents of addrspaceRefs
         assert forall p :: p != l1PTPage ==> !(p in addrspaceRefs(pageDbOut, addrspacePage));
	     assert l1PTPage in addrspaceRefs(pageDbOut, addrspacePage);
         assert addrspaceRefs(pageDbOut, addrspacePage) == {l1PTPage};
         // only kept for readability
         assert validPageDbEntry(pageDbOut, l1PTPage);

         forall ( n | validPageNr(n)
             && pageDbOut[n].PageDbEntryTyped?
             && n != addrspacePage && n != l1PTPage)
             ensures validPageDbEntryTyped(pageDbOut, n)
         {
             assert pageDbOut[n] == pageDbIn[n];
             assert addrspaceRefs(pageDbOut, n) == addrspaceRefs(pageDbIn, n);
         }
              
         assert pageDbEntriesValid(pageDbOut);
         assert validPageDb(pageDbOut);
    }
}


lemma removePreservesPageDBValidity(pageDbIn: PageDb, page: PageNr)
    requires validPageDb(pageDbIn)
    ensures  validPageDb(smc_remove(pageDbIn, page).0)
{

    reveal_validPageDb();
    var pageDbOut := smc_remove(pageDbIn, page).0;
    var errOut := smc_remove(pageDbIn, page).1;

    if ( errOut != KEV_ERR_SUCCESS() ){
       // trivial
    } else if( pageDbIn[page].PageDbEntryFree?) {
        // trivial
    } else {

        var entry := pageDbIn[page].entry;
        var addrspacePage := pageDbIn[page].addrspace;

        forall () ensures validPageDbEntry(pageDbOut, addrspacePage);
        {
            if(entry.Addrspace?){
            } else {
                var addrspace := pageDbOut[addrspacePage].entry;

                var oldRefs := addrspaceRefs(pageDbIn, addrspacePage);
                assert addrspaceRefs(pageDbOut, addrspacePage) == oldRefs - {page};
                assert addrspace.refcount == |addrspaceRefs(pageDbOut, addrspacePage)|;
                
                //assert validAddrspace(pageDbOut, addrspace);
                assert validAddrspacePage(pageDbOut, addrspacePage);
            }
        }

        assert validPageDbEntry(pageDbOut, page);

        forall ( n | validPageNr(n) && n != addrspacePage && n != page )
            ensures validPageDbEntry(pageDbOut, n)
        {
            if(pageDbOut[n].PageDbEntryFree?) {
                // trivial
            } else {
                var e := pageDbOut[n].entry;
                var d := pageDbOut;
                var a := pageDbOut[n].addrspace;

                assert pageDbOut[n] == pageDbIn[n];

                
                forall () ensures pageDbEntryOk(d, n){
                  
                    // This is a proof that the addrspace of n is still an addrspace
                    //
                    // The only interesting case is when the page that was
                    // removed is the addrspace of n (i.e. a == page). This
                    // case causes an error because a must have been valid in
                    // pageDbIn and therefore n has a reference to it.
                    forall() ensures a in d && d[a].PageDbEntryTyped?
                        && d[a].entry.Addrspace?;
                    {
                        assert a == page ==> n in addrspaceRefs(pageDbIn, a);
                        assert a == page ==> pageDbIn[a].entry.refcount > 0;
                        assert a != page;
                    }

                    if( a == addrspacePage ) {
                        var oldRefs := addrspaceRefs(pageDbIn, addrspacePage);
                        assert addrspaceRefs(pageDbOut, addrspacePage) == oldRefs - {page};
                        assert pageDbOut[a].entry.refcount == |addrspaceRefs(pageDbOut, addrspacePage)|;
                    } else {
                        assert pageDbOut[a].entry.refcount == pageDbIn[a].entry.refcount;
                        assert addrspaceRefs(pageDbIn, a) == addrspaceRefs(pageDbOut, a);
                    }

                }

            }
        }

        assert pageDbEntriesValid(pageDbOut);
        assert validPageDb(pageDbOut);
    }
}

lemma mapSecurePreservesPageDBValidity(pageDbIn: PageDb, page: PageNr, addrspacePage: PageNr,
    mapping: Mapping, physPage: int)
    requires validPageDb(pageDbIn)
    ensures  validPageDb(smc_mapSecure(pageDbIn, page, addrspacePage,
        mapping, physPage).0)
{
    reveal_validPageDb();
    var pageDbOut := smc_mapSecure(
        pageDbIn, page, addrspacePage, mapping, physPage).0;
    var err := smc_mapSecure(
        pageDbIn, page, addrspacePage, mapping, physPage).1;

    if( err != KEV_ERR_SUCCESS() ){
    } else {
        assert validPageDbEntryTyped(pageDbOut, page);
        
        var pageDbA := allocatePage(pageDbIn, page,
            addrspacePage, DataPage).0;
       
        forall() ensures validPageDbEntryTyped(pageDbOut, addrspacePage){
            var a := addrspacePage;
            assert pageDbOut[a].entry.refcount == pageDbA[a].entry.refcount;
            assert addrspaceRefs(pageDbOut, a) == addrspaceRefs(pageDbA, a);
        }

        forall( n | validPageNr(n)
            && pageDbOut[n].PageDbEntryTyped?
            && n != page && n != addrspacePage)
            ensures validPageDbEntryTyped(pageDbOut, n);
        {
            if( pageDbOut[n].entry.Addrspace? ){
                assert pageDbOut[n].entry.refcount == pageDbA[n].entry.refcount;
                assert addrspaceRefs(pageDbOut, n) == addrspaceRefs(pageDbA, n);
            } else {
                // trivial
            }
        }
    }

}

lemma mapInsecurePreservesPageDbValidity(pageDbIn: PageDb, addrspacePage: PageNr,
    physPage: int, mapping : Mapping)
    requires validPageDb(pageDbIn)
    ensures  validPageDb(smc_mapInsecure(pageDbIn, addrspacePage, physPage, mapping).0)
{
    reveal_validPageDb();
    var pageDbOut := smc_mapInsecure(
        pageDbIn, addrspacePage, physPage, mapping).0;
    var err := smc_mapInsecure(
        pageDbIn, addrspacePage, physPage, mapping).1;

    if( err != KEV_ERR_SUCCESS() ){
    } else {        
        forall() ensures validPageDbEntryTyped(pageDbOut, addrspacePage){
            var a := addrspacePage;
            assert pageDbOut[a].entry.refcount == pageDbIn[a].entry.refcount;
            assert addrspaceRefs(pageDbOut, a) == addrspaceRefs(pageDbIn, a);
        }

        forall( n | validPageNr(n)
            && pageDbOut[n].PageDbEntryTyped?
            && n != addrspacePage)
            ensures validPageDbEntryTyped(pageDbOut, n);
        {
            if( pageDbOut[n].entry.Addrspace? ){
                assert pageDbOut[n].entry.refcount == pageDbIn[n].entry.refcount;
                assert addrspaceRefs(pageDbOut, n) == addrspaceRefs(pageDbIn, n);
            } else {
                // trivial
            }
        }
    }
}

lemma finalisePreservesPageDbValidity(pageDbIn: PageDb, addrspacePage: PageNr)
    requires validPageDb(pageDbIn)
    ensures  validPageDb(smc_finalise(pageDbIn, addrspacePage).0)
{
    reveal_validPageDb();
    var pageDbOut := smc_finalise(pageDbIn, addrspacePage).0;
    var err := smc_finalise(pageDbIn, addrspacePage).1;

    if( err != KEV_ERR_SUCCESS() ){
    } else {
        var a := addrspacePage;
        assert pageDbOut[a].entry.refcount == pageDbIn[a].entry.refcount;
        assert addrspaceRefs(pageDbOut, a) == addrspaceRefs(pageDbIn, a);

        forall ( n | validPageNr(n) 
            && pageDbOut[n].PageDbEntryTyped?
            && n != a )
            ensures validPageDbEntry(pageDbOut, n)
        {
            if( pageDbOut[n].entry.Addrspace? ){
                assert pageDbOut[n].entry.refcount == pageDbIn[n].entry.refcount;
                assert addrspaceRefs(pageDbOut, n) == addrspaceRefs(pageDbIn, n);
            } else {
            }

        }
    }
}

lemma enterPreservesPageDbValidity(pageDbIn: PageDb, dispPage: PageNr,
    arg1: int, arg2: int, arg3: int)
    requires validPageDb(pageDbIn) 
    ensures validPageDb(smc_enter(pageDbIn, dispPage, arg1, arg2, arg3).0)
{
    reveal_validPageDb();
    var pageDbOut := smc_enter(pageDbIn, dispPage, arg1, arg2, arg3).0;
    var err := smc_enter(pageDbIn, dispPage, arg1, arg2, arg3).1;

    if( err != KEV_ERR_SUCCESS() ){
    } else {
        var a := pageDbOut[dispPage].addrspace;
        assert pageDbOut[a].entry.refcount == pageDbIn[a].entry.refcount;
        assert addrspaceRefs(pageDbOut, a) == addrspaceRefs(pageDbIn, a);

        forall ( n | validPageNr(n) 
            && pageDbOut[n].PageDbEntryTyped?
            && n != a )
            ensures validPageDbEntry(pageDbOut, n)
        {
            if( pageDbOut[n].entry.Addrspace? ){
                assert pageDbOut[n].entry.refcount == pageDbIn[n].entry.refcount;
                assert addrspaceRefs(pageDbOut, n) == addrspaceRefs(pageDbIn, n);
            } else {
            }

        }
    }
}

lemma resumePreservesPageDbValidity(pageDbIn: PageDb, dispPage: PageNr)
    requires validPageDb(pageDbIn) 
    ensures validPageDb(smc_resume(pageDbIn, dispPage).0)
{
    reveal_validPageDb();
    var pageDbOut := smc_resume(pageDbIn, dispPage).0;
    var err := smc_resume(pageDbIn, dispPage).1;

    if( err != KEV_ERR_SUCCESS() ){
    } else {
        var a := pageDbOut[dispPage].addrspace;
        assert pageDbOut[a].entry.refcount == pageDbIn[a].entry.refcount;
        assert addrspaceRefs(pageDbOut, a) == addrspaceRefs(pageDbIn, a);

        forall ( n | validPageNr(n) 
            && pageDbOut[n].PageDbEntryTyped?
            && n != a )
            ensures validPageDbEntry(pageDbOut, n)
        {
            if( pageDbOut[n].entry.Addrspace? ){
                assert pageDbOut[n].entry.refcount == pageDbIn[n].entry.refcount;
                assert addrspaceRefs(pageDbOut, n) == addrspaceRefs(pageDbIn, n);
            } else {
            }

        }

    }
}

lemma stopPreservesPageDbValidity(pageDbIn: PageDb, addrspacePage: PageNr)
    requires validPageDb(pageDbIn)
    ensures  validPageDb(smc_stop(pageDbIn, addrspacePage).0)
{
    reveal_validPageDb();
    var pageDbOut := smc_stop(pageDbIn, addrspacePage).0;
    var err := smc_stop(pageDbIn, addrspacePage).1;

    if( err != KEV_ERR_SUCCESS() ){
    } else {
        var a := addrspacePage;
        assert pageDbOut[a].entry.refcount == pageDbIn[a].entry.refcount;
        assert addrspaceRefs(pageDbOut, a) == addrspaceRefs(pageDbIn, a);

        forall ( n | validPageNr(n) 
            && pageDbOut[n].PageDbEntryTyped?
            && n != a )
            ensures validPageDbEntry(pageDbOut, n)
        {
            if( pageDbOut[n].entry.Addrspace? ){
                assert pageDbOut[n].entry.refcount == pageDbIn[n].entry.refcount;
                assert addrspaceRefs(pageDbOut, n) == addrspaceRefs(pageDbIn, n);
            } else {
            }

        }

    }
}

lemma smchandlerPreservesPageDbValidity(pageDbIn: PageDb, callno: int, arg1: int,
    arg2: int, arg3: int, arg4: int)
    requires validPageDb(pageDbIn)
    ensures validPageDb(smchandler(pageDbIn, callno, arg1, arg2, arg3, arg4).0)
{
    reveal_validPageDb();
    if (callno == KEV_SMC_INIT_ADDRSPACE()) {
        initAddrspacePreservesPageDBValidity(pageDbIn, arg1, arg2);
    } else if(callno == KEV_SMC_INIT_DISPATCHER()) {
    } else if(callno == KEV_SMC_INIT_L2PTABLE()) {
    } else if(callno == KEV_SMC_MAP_SECURE()) {
        mapSecurePreservesPageDBValidity(pageDbIn, arg1, arg2, intToMapping(arg3), arg4);
    } else if(callno == KEV_SMC_MAP_INSECURE()) {
        mapInsecurePreservesPageDbValidity(pageDbIn, arg1, arg2, intToMapping(arg3));
    } else if(callno == KEV_SMC_REMOVE()) {
        removePreservesPageDBValidity(pageDbIn, arg1);
    } else if(callno == KEV_SMC_FINALISE()) {
        finalisePreservesPageDbValidity(pageDbIn, arg1);
    } else if(callno == KEV_SMC_ENTER()) {
        enterPreservesPageDbValidity(pageDbIn, arg1, arg2, arg3, arg4);
    } else if(callno == KEV_SMC_RESUME()) {
        resumePreservesPageDbValidity(pageDbIn, arg1);
    } else if(callno == KEV_SMC_STOP()) {
        stopPreservesPageDbValidity(pageDbIn, arg1);
    }
}
