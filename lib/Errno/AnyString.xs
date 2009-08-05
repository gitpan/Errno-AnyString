#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef PERL_MAGIC_sv
#   define PERL_MAGIC_sv '\0'
#endif

MODULE = Errno::AnyString		PACKAGE = Errno::AnyString		

void
_set_errno_magic(target_sv)
    SV * target_sv;

    PROTOTYPE: $
    CODE:
        sv_magic(target_sv, target_sv, PERL_MAGIC_sv, "!", 1);

void
_clear_errno_magic(target_sv)
    SV * target_sv;

    PROTOTYPE: $
    CODE:
        sv_unmagic(target_sv, PERL_MAGIC_sv);

