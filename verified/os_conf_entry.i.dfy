include "sec_prop.s.dfy"
include "pagedb.s.dfy"
include "entry.s.dfy"
include "sec_prop_util.i.dfy"
include "smcapi.i.dfy"

predicate same_ret(s1:state, s2:state)
    requires ValidState(s1) && ValidState(s2)
{
    reveal ValidRegState();
    s1.regs[R0] == s2.regs[R0] &&
    s1.regs[R1] == s2.regs[R1]
}

lemma lemma_enter_os_conf_ni(
    s1: state, d1: PageDb, s1':state, d1': PageDb,
    s2: state, d2: PageDb, s2':state, d2': PageDb,
    dispPage: word, arg1: word, arg2: word, arg3: word)
    requires os_ni_reqs(s1, d1, s1', d1', s2, d2, s2', d2')
    requires s1.conf.nondet == s2.conf.nondet
    requires os_conf_eq(s1, d1, s2, d2)
    requires smc_enter(s1, d1, s1', d1', dispPage, arg1, arg2, arg3)
    requires smc_enter(s2, d2, s2', d2', dispPage, arg1, arg2, arg3)
    ensures  os_conf_eqpdb(d1', d2')
    ensures  same_ret(s1', s2')
    ensures  InsecureMemInvariant(s1', s2')
{
    var e1', e2' := smc_enter_err(d1, dispPage, false), 
        smc_enter_err(d2, dispPage, false);
    assert e1' == e2' by {
        reveal os_conf_eqpdb();
    }
    if(e1' != KOM_ERR_SUCCESS) {
        assert os_conf_eqpdb(d1', d2');
        assert same_ret(s1', s2');
        assert InsecureMemInvariant(s1', s2');
    } else {
        var s11:state, steps1: nat :|
            preEntryEnter(s1, s11, d1, dispPage, arg1, arg2, arg3) &&
            validEnclaveExecution(s11, d1, s1', d1', dispPage, steps1);
        
        var s21:state, steps2: nat :|
            preEntryEnter(s2, s21, d2, dispPage, arg1, arg2, arg3) &&
            validEnclaveExecution(s21, d2, s2', d2', dispPage, steps2);
        
        assert s11.conf.nondet == s21.conf.nondet;
        
        lemma_validEnclaveEx_os_conf(s11, d1, s1', d1', s21, d2, s2', d2',
                                             dispPage, steps1, steps2);
    }
}

lemma lemma_resume_os_conf_ni(
    s1: state, d1: PageDb, s1':state, d1': PageDb,
    s2: state, d2: PageDb, s2':state, d2': PageDb,
    dispPage: word)
    requires os_ni_reqs(s1, d1, s1', d1', s2, d2, s2', d2')
    requires s1.conf.nondet == s2.conf.nondet
    requires smc_resume(s1, d1, s1', d1', dispPage)
    requires smc_resume(s2, d2, s2', d2', dispPage)
    requires os_conf_eq(s1, d1, s2, d2)
    ensures  os_conf_eqpdb(d1', d2')
    ensures  same_ret(s1', s2')
    ensures  InsecureMemInvariant(s1', s2')
{
    var e1', e2' := smc_enter_err(d1, dispPage, true), 
        smc_enter_err(d2, dispPage, true);
    assert e1' == e2' by {
        reveal os_conf_eqpdb();
    }
    if(e1' != KOM_ERR_SUCCESS) {
        assert os_conf_eqpdb(d1', d2');
        assert same_ret(s1', s2');
        assert InsecureMemInvariant(s1', s2');
    } else {
        var s11:state, steps1: nat :|
            preEntryResume(s1, s11, d1, dispPage) &&
            validEnclaveExecution(s11, d1, s1', d1', dispPage, steps1);
        
        var s21:state, steps2: nat :|
            preEntryResume(s2, s21, d2, dispPage) &&
            validEnclaveExecution(s21, d2, s2', d2', dispPage, steps2);
        
        assert s11.conf.nondet == s21.conf.nondet;
       
        lemma_validEnclaveEx_os_conf(s11, d1, s1', d1', s21, d2, s2', d2',
            dispPage, steps1, steps2);
    }
}

lemma lemma_validEnclaveEx_os_conf(
    s1: state, d1: PageDb, s1': state, d1': PageDb,
    s2: state, d2: PageDb, s2': state, d2': PageDb,
    dispPg:PageNr, steps1:nat, steps2:nat)
    requires SaneConstants()
    requires ValidState(s1) && ValidState(s2) &&
        ValidState(s1') && ValidState(s2')
    requires validPageDb(d1) && validPageDb(d2) &&
        validPageDb(d1') && validPageDb(d2')
    requires nonStoppedDispatcher(d1, dispPg)
    requires nonStoppedDispatcher(d2, dispPg)
    requires validEnclaveExecution(s1, d1, s1', d1', dispPg, steps1);
    requires validEnclaveExecution(s2, d2, s2', d2', dispPg, steps2);
    requires os_conf_eqpdb(d1, d2)
    requires InsecureMemInvariant(s1, s2)
    requires s1.conf.nondet == s2.conf.nondet
    ensures  os_conf_eqpdb(d1', d2')
    ensures  same_ret(s1', s2')
    ensures  InsecureMemInvariant(s1', s2')
    decreases steps1, steps2
{
    reveal_validEnclaveExecution();

    var retToEnclave1, s15, d15 := lemma_unpack_validEnclaveExecution(
        s1, d1, s1', d1', dispPg, steps1);
    var retToEnclave2, s25, d25 := lemma_unpack_validEnclaveExecution(
        s2, d2, s2', d2', dispPg, steps2);

    lemma_validEnclaveExecutionStep_validPageDb(s1, d1, s15, d15, dispPg, retToEnclave1);
    lemma_validEnclaveExecutionStep_validPageDb(s2, d2, s25, d25, dispPg, retToEnclave2);
    lemma_validEnclaveStep_os_conf(s1, d1, s15, d15, s2, d2, s25, d25,
        dispPg, retToEnclave1, retToEnclave2);

    assert retToEnclave1 == retToEnclave2;

    if(retToEnclave1) {
        lemma_validEnclaveExecution(s15, d15, s1', d1', dispPg, steps1 - 1);
        lemma_validEnclaveExecution(s25, d25, s2', d2', dispPg, steps2 - 1);
        lemma_validEnclaveEx_os_conf(s15, d15, s1', d1', s25, d25, s2', d2',
                                         dispPg, steps1 - 1, steps2 - 1);
        assert os_conf_eqpdb(d1', d2');
    } else {
        assert s2' == s25;
        assert s1' == s15;
        assert d1' == d15;
        assert d2' == d25;
        assert os_conf_eqpdb(d1', d2');
    }
}

lemma lemma_validEnclaveStep_os_conf(s1: state, d1: PageDb, s1':state, d1': PageDb,
                                     s2: state, d2: PageDb, s2':state, d2': PageDb,
                                     dispPage:PageNr, ret1:bool, ret2:bool)
    requires ValidState(s1) && ValidState(s2) &&
             ValidState(s1') && ValidState(s2') &&
             validPageDb(d1) && validPageDb(d2) && 
             validPageDb(d1') && validPageDb(d2') && SaneConstants()
    requires s1.conf.nondet == s2.conf.nondet
    requires nonStoppedDispatcher(d1, dispPage)
    requires nonStoppedDispatcher(d2, dispPage)
    requires validEnclaveExecutionStep(s1, d1, s1', d1', dispPage, ret1);
    requires validEnclaveExecutionStep(s2, d2, s2', d2', dispPage, ret2);
    requires os_conf_eqpdb(d1, d2)
    requires InsecureMemInvariant(s1, s2)
    ensures  os_conf_eqpdb(d1', d2')
    ensures  InsecureMemInvariant(s1', s2')
    ensures  same_ret(s1', s2')
    ensures  ret1 == ret2
    ensures  ret1 ==> s1'.conf.nondet == s2'.conf.nondet;
{
    reveal validEnclaveExecutionStep();
    var s14, d14 :|
        validEnclaveExecutionStep'(s1, d1, s14, d14, s1', d1',
            dispPage, ret1);

    var s24, d24 :|
        validEnclaveExecutionStep'(s2, d2, s24, d24, s2', d2',
            dispPage, ret2);

    lemma_validEnclaveStepPrime_os_conf(
        s1, d1, s14, d14, s1', d1',
        s2, d2, s24, d24, s2', d2',
        dispPage, ret1, ret2);
}

lemma lemma_validEnclaveStepPrime_os_conf(
s11: state, d11: PageDb, s14:state, d14:PageDb, r1:state, rd1:PageDb,
s21: state, d21: PageDb, s24:state, d24:PageDb, r2:state, rd2:PageDb,
dispPg:PageNr, retToEnclave1:bool, retToEnclave2:bool
)
    requires ValidState(s11) && ValidState(s21) &&
             ValidState(r1)  && ValidState(r2)  &&
             validPageDb(d11) && validPageDb(d21) &&
             validPageDb(rd1) && validPageDb(rd2) && SaneConstants()
    requires s11.conf.nondet == s21.conf.nondet
    requires nonStoppedDispatcher(d11, dispPg)
    requires nonStoppedDispatcher(d21, dispPg)
    requires validEnclaveExecutionStep'(s11,d11,s14,d14,r1,rd1,dispPg,retToEnclave1)
    requires validEnclaveExecutionStep'(s21,d21,s24,d24,r2,rd2,dispPg,retToEnclave2)
    requires InsecureMemInvariant(s11, s21)
    requires os_conf_eqpdb(d11, d21)
    ensures  InsecureMemInvariant(r1, r2)
    ensures  os_conf_eqpdb(rd1, rd2)
    ensures  same_ret(r1, r2)
    ensures  retToEnclave1 == retToEnclave2
    ensures  retToEnclave1 ==> r1.conf.nondet == r2.conf.nondet
{
    assert l1pOfDispatcher(d11, dispPg) == l1pOfDispatcher(d21, dispPg) by
        { reveal os_conf_eqpdb(); }
    var l1p := l1pOfDispatcher(d11, dispPg);

    assert dataPagesCorrespond(s11.m, d11);
    assert dataPagesCorrespond(s21.m, d21);
    
    assert userspaceExecutionAndException(s11, s14);
    assert userspaceExecutionAndException(s21, s24);
    
    reveal userspaceExecutionAndException();

    var s1', s12 :| userspaceExecutionAndException'(s11, s1', s12, s14);
    var s2', s22 :| userspaceExecutionAndException'(s21, s2', s22, s24);

    var pc1 := OperandContents(s11, OLR);
    var pc2 := OperandContents(s21, OLR);
    
    var (s13, expc1, ex1) := userspaceExecutionFn(s12, pc1);
    var (s23, expc2, ex2) := userspaceExecutionFn(s22, pc2);

    assert InsecureMemInvariant(s12, s22) by {
        assert InsecureMemInvariant(s11, s12);
        assert InsecureMemInvariant(s21, s22);
    }

    var pt1 := ExtractAbsPageTable(s12);
    var pt2 := ExtractAbsPageTable(s22);

    assert pageTableCorresponds(s12, d11, l1p)
        && pageTableCorresponds(s22, d21, l1p) by
    { 
        assert pageTableCorresponds(s11, d11, l1p);
        assert pageTableCorresponds(s21, d21, l1p);
        reveal pageTableCorresponds();
    }

    assert pt1 == pt2 by {
        lemma_eqpdb_pt_coresp(d11, d21, s12, s22, l1p);
    }

    assert s12.conf.nondet == s22.conf.nondet;

    assert InsecureMemInvariant(s13, s23) by {
        lemma_insecure_mem_userspace(
            s12, pc1, s13, expc1, ex1,
            s22, pc2, s23, expc2, ex2);
    }

    assert s13.conf.nondet == s23.conf.nondet by
    {
        reveal userspaceExecutionFn();
        assert s13.conf.nondet == nondet_int(s12.conf.nondet, NONDET_GENERATOR());
        assert s23.conf.nondet == nondet_int(s22.conf.nondet, NONDET_GENERATOR());
    }
    assume false;
}

function insecureUserspaceMem(s:state, pc:word, a:addr): word
    requires ValidState(s)
    requires ValidMem(a) && a in TheValidAddresses()
    requires !addrIsSecure(a)
    requires ExtractAbsPageTable(s).Just?
{
    var pt := ExtractAbsPageTable(s).v;
    var user_state := user_visible_state(s, pc, pt);
    var pages := WritablePagesInTable(pt);
    if( PageBase(a) in pages ) then nondet_word(s.conf.nondet, a)
    else MemContents(s.m, a)
}

lemma lemma_userspace_insecure_addr(s:state, pc: word, s3: state, a:addr)
    requires validStates({s, s3})
    requires mode_of_state(s) == User
    requires ValidMem(a) && a in TheValidAddresses()
    requires !addrIsSecure(a)
    requires ExtractAbsPageTable(s).Just?
    requires userspaceExecutionFn(s, pc).0 == s3
    ensures  MemContents(s3.m, a) == insecureUserspaceMem(s, pc, a)
{
    var pt := ExtractAbsPageTable(s).v;
    var user_state := user_visible_state(s, pc, pt);
    var pages := WritablePagesInTable(pt);
    var newpsr := nondet_psr(s.conf.nondet, user_state, s.conf.cpsr);
    var hv := havocPages(pages, s, user_state);
    assert s3.m.addresses == hv by
        { reveal userspaceExecutionFn(); }
}

lemma lemma_insecure_mem_userspace(
    s12: state, pc1: word, s13: state, expc1: word, ex1: exception,
    s22: state, pc2: word, s23: state, expc2: word, ex2: exception)
    requires validStates({s12, s13, s22, s23})
    requires SaneConstants()
    requires InsecureMemInvariant(s12, s22)
    requires s12.conf.nondet == s22.conf.nondet
    requires mode_of_state(s12) == mode_of_state(s22) == User;
    requires 
        var pt1 := ExtractAbsPageTable(s12);
        var pt2 := ExtractAbsPageTable(s22);
        pt1.Just? && pt2.Just? && pt1 == pt2
    requires userspaceExecutionFn(s12, pc1) == (s13, expc1, ex1)
    requires userspaceExecutionFn(s22, pc2) == (s23, expc2, ex2)
    ensures InsecureMemInvariant(s13, s23)
{
    reveal ValidMemState();
    var pt := ExtractAbsPageTable(s12).v;
    var pages := WritablePagesInTable(pt);

    forall( a | ValidMem(a) && !addrIsSecure(a) )
        ensures s13.m.addresses[a] == s23.m.addresses[a]
    {
        var m1 := insecureUserspaceMem(s12, pc1, a);
        var m2 := insecureUserspaceMem(s22, pc2, a);
        lemma_userspace_insecure_addr(s12, pc1, s13, a);
        lemma_userspace_insecure_addr(s22, pc2, s23, a);
        assert s13.m.addresses[a] == m1;
        assert s23.m.addresses[a] == m2;
        if(PageBase(a) in pages) {
            assert m1 == nondet_word(s12.conf.nondet, a);
            assert m2 == nondet_word(s22.conf.nondet, a);
            assert s12.conf.nondet == s22.conf.nondet;
        } else {
            assert m1 == MemContents(s12.m, a);
            assert m2 == MemContents(s22.m, a);
            assert InsecureMemInvariant(s12, s22);
            assert !address_is_secure(a);
            assert KOM_DIRECTMAP_VBASE <= a < KOM_DIRECTMAP_VBASE + MonitorPhysBase();
            assert m1 == m2;
        }
    }
    lemma_insecure_mem_helper(s13, s23);
}

predicate insec_mem_invar(s1:state, s2:state)
    requires validStates({s1, s2})
{
    reveal ValidMemState();
    forall a | ValidMem(a) && !address_is_secure(a) ::
        s1.m.addresses[a] == s2.m.addresses[a]
}

lemma lemma_insecure_mem_helper(s1:state, s2:state)
    requires validStates({s1, s2})
    requires insec_mem_invar(s1, s2)
    requires SaneConstants()
    ensures InsecureMemInvariant(s1, s2)
{
    reveal ValidMemState();
}

lemma lemma_eqpdb_pt_coresp(d1: PageDb, d2: PageDb, s1: state, s2: state, l1p:PageNr)
    requires validPageDb(d1) && validPageDb(d2)
    requires ValidState(s1) && ValidState(s2)
    requires ValidState(s1) && ValidState(s2) && SaneConstants()
    requires os_conf_eqpdb(d1, d2)
    requires nonStoppedL1(d1, l1p) && nonStoppedL1(d2, l1p)
    requires pageTableCorresponds(s1, d1, l1p)
    requires pageTableCorresponds(s2, d2, l1p)
    ensures  ExtractAbsPageTable(s1) == ExtractAbsPageTable(s2)
{
    reveal pageTableCorresponds();
    assert mkAbsPTable(d1, l1p) == mkAbsPTable(d2, l1p) by {
        reveal os_conf_eqpdb();
        reveal validPageDb();
        reveal mkAbsPTable();
    }
}

// lemma lemma_userspaceInsecureMem_os_conf(
// s12:state, s13:state, 
