#
# Makefile -- 
# 
# Author          : Max Root
# Created On      : Sat Jul  6 16:07:08 2002
# Last Modified By: Maximum Solo
# Last Modified On: Sat Oct  8 09:52:26 2011
# Update Count    : 146
# Status          : Very good Makefile !!!
#

#
# Après une réinstallation des prc-tools, lancer :
#   palmdev-prep /usr/local/palmdev
#

TARGET=		obj

PRC_NAME=	MaTirelire2
CREATOR_ID=	MaT2

OBJSRC=		main.m alarm.m

CLASSESSRC=	Object.m \
		BaseForm.m MaTiForm.m \
		MiniStatsForm.m \
		SumListForm.m \
		RepeatsListForm.m \
		ScrollList.m SumScrollList.m \
		ClearingScrollList.m \
		ClearingListForm.m \
		StatementNumForm.m \
		RepeatsScrollList.m \
		ClearingAutoConfForm.m \
		ExportForm.m \
		ClearingIntroForm.m \
		StatsForm.m \
		SearchForm.m \
		CustomScrollList.m \
		StatsTransScrollList.m \
		StatsTransFlaggedScrollList.m StatsTransAllScrollList.m \
		StatsTypeScrollList.m \
		StatsPeriodScrollList.m \
		StatsModeScrollList.m \
		AccountsScrollList.m TransScrollList.m \
		PurgeForm.m TransForm.m \
		DescModesListForm.m \
		CustomListForm.m \
		TransListForm.m \
		SumDatesForm.m \
		AccountsListForm.m AccountPropForm.m \
		TypesListForm.m CurrenciesListForm.m \
		EditDescForm.m EditModeForm.m EditTypeForm.m \
		EditSplitForm.m \
		PrefsForm.m AboutForm.m PasswordForm.m ProgressBar.m \
		DBasesListForm.m DBasePropForm.m \
		DBItem.m DBItemId.m Type.m \
		Transaction.m Desc.m \
		Mode.m \
		Array.m Hash.m \
		\
		Application.m \
		MaTirelire.m \
		Currency.m \
		EditCurrencyForm.m \
		ExternalCurrencyGlobal.m \
		ExternalCurrency.m \
		ExternalCurrencyMaTi.m ExternalCurrencyCur4.m\


PALMRESIZE_SRC=	DIA.c resize.c
PALMRESIZE_SRC_FULL=	$(PALMRESIZE_SRC:S/^/$(.CURDIR)\//)

SRC=		mem.c misc.c float.c FontBucket.c db_list.c $(PALMRESIZE_SRC)

BITMAPS!=	echo ${.CURDIR}/bmp/*.bmp

OBJS=		$(OBJSRC:.m=.o) $(CLASSESSRC:.m=.o) $(SRC:.c=.o)

CLASSES_DEPEND=		classes.lst
CLASSES_DEPEND_H=	$(CLASSES_DEPEND:.lst=.h)

PALMDEV=	/usr/local/palmdev
SDK=		$(PALMDEV)/sdk-5
GLUE_BASE=	$(SDK)
GLUE_INC=	$(GLUE_BASE)/include/Libraries
GLUE_LIB=	$(GLUE_BASE)/lib/m68k-palmos-coff
SONY_SDK=	$(PALMDEV)/sony-sdk
PALM_SDK=	$(PALMDEV)/PalmSDK/Incs
HANDERA_SDK=	$(PALMDEV)/handera-sdk
BASE=		/usr/local/pilot/bin
CC=		$(BASE)/m68k-palmos-gcc

# XXX -mdebug-labels à supprimer de la version de prod XXX
CFLAGS= 	-Wall -Werror -g -O2 -fno-builtins -palmos5 \
		-include $(.CURDIR)/winprintf.h \
		-I$(.OBJDIR) \
		-I$(GLUE_INC) -I$(GLUE_INC)/PalmOSGlue \
		-I$(SONY_SDK) \
		-I$(SONY_SDK)/System \
		-I$(SONY_SDK)/Libraries \
		-DFB_SONY_SUPPORT \
		-I$(HANDERA_SDK) \
		-I$(PALM_SDK) \
		-I$(PALM_SDK)/Common/System \
		-I$(PALM_SDK)/68k/System \
		-DFB_HANDERA_SUPPORT \
		\
		-DSUPPORT_DIA -DSUPPORT_DIA_SONY -DSUPPORT_DIA_HANDERA \
		-I$(.CURDIR)/PalmResize

.ifdef BETA
FLAG_BETA=	-DBETA
CFLAGS+=	-mdebug-labels $(FLAG_BETA)
.endif

MCC=		/usr/local/bin/mcc.pl
AS=		$(BASE)/m68k-palmos-as
MULTILINK=	$(BASE)/m68k-palmos-multilink
PILRC=		$(.CURDIR)/translate2.pl
BUILDPRC= 	build-prc

# Pour ajouter un langage, ajouter XX ici ET #include "obj-xx.rcp" dans obj.rcp
# PT
RCLANG=		FR EN DE IT TW BR

TW_FONT=	-F5 -noEllipsis # Fonte spéciale pour la langue TW
CN_FONT=	-Fg -noEllipsis # Fonte spéciale pour la langue CN


ALL_PRC=	$(RCLANG:L:S/^/$(TARGET)-/:S/$/.prc/)	# MaTirelire-xx.prc
ALL_RCP=	$(ALL_PRC:.prc=.rcp)			# MaTirelire-xx.rcp
ALL_RCS_DIRS=	$(RCLANG:L:S/^/rsc-/)			# rsc-xx

TKIT=		MaTirelire-translate
TKIT_TMPL=	$(TKIT).tmpl


.MAIN: all

all: $(.CURDIR)/.build

$(.CURDIR)/.build: $(ALL_PRC)
	@perl -e '\
		my $$cur_build = 0; \
		if (open(BUILD, "$(.CURDIR)/.build")) \
		{ \
		    $$cur_build = <BUILD> || 0; \
		    close BUILD; \
		    chomp $$cur_build; \
		    $$cur_build++; \
		} \
		if (open(BUILD, ">$(.CURDIR)/.build")) \
		{ \
		    print BUILD "$$cur_build\n"; \
		    close BUILD; \
		    print "Next BUILD number set: $$cur_build\n"; \
		} \
		'

$(ALL_PRC): rsc-$(@:S/$(TARGET)-//:S/.prc//:L) $(TARGET)0000.out
	cd rsc-$(@:S/$(TARGET)-//:S/.prc//) \
		&& for i in ../*.grc; do ln -f $$i; done \
		&& $(BUILDPRC) --backup ../$@ $(PRC_NAME) $(CREATOR_ID) \
					*.bin *.grc
.ifdef BETA
	@perl -e '\
		open(BUILD, "$(.CURDIR)/.build") \
			or die "Can not open $(.CURDIR)/.build: $$!\n"; \
		my $$cur_build = sprintf("%04u", <BUILD> || 0); \
		close BUILD; \
		\
		$$/ = undef; \
		open(PRC, "+<$@") || die "Can not open $@: $$!\n"; \
		my $$c = <PRC>; \
		unless ($$c =~ s/- bZZZZ\0/- b$$cur_build\0/g) \
		{ die "Can not find build template in $@\n" } \
		seek(PRC, 0, 0); \
		print PRC $$c; \
		close PRC; \
		'
.endif

translators.txt: $(ALL_RCP)
	perl -e ' \
		my @content; \
		foreach my $$rcp (sort qw($(ALL_RCP))) \
		{ \
		    my %infos; \
		    open(RCP, "$(.CURDIR)/$$rcp") \
			or die "Can not open $(.CURDIR)/$$rcp: $$!\n"; \
		    while (defined(my $$line = <RCP>)) \
		    { \
			if ($$line =~ \
			    /^"\$$Language(Lang|Author|Email)"\s*=\s*"(.*)"/) \
			{ \
			    $$infos{$$1} = $$2; \
			    last if keys(%infos) == 3; \
			} \
                    } \
		    close RCP; \
		    push(@contents, \
			 "$$infos{Lang}: $$infos{Author} ($$infos{Email})"); \
		} \
		open(TRANS, ">", "$@") or die "Can not open $@: $$!\n"; \
		print TRANS join("\n", @contents), "\n"; \
		close TRANS; \
		'

# ok
$(ALL_RCS_DIRS): $(.CURDIR)/$(TARGET).rcp translators.txt $(.CURDIR)/MaTirelireDefs.h $(BITMAPS)
	mkdir -p $@
	rm -f $@/*
	$(PILRC) -I $(.CURDIR) -L $(@:S/rsc-//:U) $($(@:S/rsc-//:U)_FONT) \
		 -q -H $(TARGET)Rsc-tmp.h.new $(.CURDIR)/$(TARGET).rcp $@ \
		&& sort $(TARGET)Rsc-tmp.h.new > $(TARGET)Rsc.h.new \
		&& rm -f $(TARGET)Rsc-tmp.h.new
	@-(diff -q $(TARGET)Rsc.h.new $(TARGET)Rsc.h > /dev/null;\
	   if [ $$? != 0 ]; then \
	       echo New $(TARGET)Rsc.h; \
	       mv $(TARGET)Rsc.h.new $(TARGET)Rsc.h; \
	   else \
	       echo $(TARGET)Rsc.h unchanged; \
	       rm $(TARGET)Rsc.h.new; \
	   fi)
# ok 
$(TARGET)0000.out: $(CLASSES_DEPEND) $(OBJS)
	rm -f *.grc rsc-*/*.grc
	$(MULTILINK) -basename $(TARGET) -fid MaT2 \
			-g -gdb-script script.gdb \
			-relocation-new -stdlib \
			$(OBJS) \
			-L$(GLUE_LIB) -lPalmOSGlue \
			-L/usr/local/pilot/lib/gcc-lib/m68k-palmos/2.95.3-kgpd

$(PALMRESIZE_SRC_FULL): $(.CURDIR)/PalmResize/$(@:T)
	ln -s PalmResize/$(@:T) $@

.SUFFIXES: .m

$(CLASSES_DEPEND) $(CLASSES_DEPEND_H): $(CLASSESSRC:.m=.h)
	env CLASSES_DEPEND=$(CLASSES_DEPEND) $(MCC) -extract-classes $>

.m.o:
	@echo "Compiling $<..."
	@env CC=$(CC) $(MCC) $(CFLAGS) -c $<

depend: rsc-fr $(PALMRESIZE_SRC:S/^/$(.CURDIR)\//) $(CLASSES_DEPEND)
	env MKDEP_CPP="${CC} -x c -E -MM $(CFLAGS)" \
		mkdep $(OBJSRC:S/^/$(.CURDIR)\//) \
		      $(CLASSESSRC:S/^/$(.CURDIR)\//) \
		      $(SRC:S/^/$(.CURDIR)\//)

pilrcclean:
	-rm -rf $(ALL_RCS_DIRS)

clean:
	rm -rf *.grc *.tmp *.out *.o \
		$(ALL_RCS_DIRS) $(ALL_PRC) \
		$(CLASSES_DEPEND) $(CLASSES_DEPEND_H) \
		MaTirelireDefsAuto.h objRsc.h \
		translators.txt script.gdb \
		.depend

# Nombre de lignes...
wc:
	@wc -l `perl -ne 'while (m, (\Q$(.CURDIR)\E/\w+\.[hcm]),g) \
			  { $$H{$$1}=1 } \
			  END { print join(" ", \
					   sort \
					   grep { !/FontBucket|DIA|resize/ } \
					   keys %H), "\n" }' \
			  $(.OBJDIR)/.depend`
	@wc -l $(.CURDIR)/$(TARGET).rcp $(ALL_RCP:S/^/$(.CURDIR)\//)

beta: $(ALL_PRC)
	@perl -e '\
		my $$build; \
		local $$/ = undef; \
		foreach my $$prc (qw($(ALL_PRC))) \
		{ \
		    open(PRC, $$prc) || die "Can not open $$prc: $$!\n"; \
		    my $$c = <PRC>; \
		    close PRC; \
		    if ($$c !~ /Ma Tirelire v2.0 beta - b(\d+)/) \
		    { die "Can not find build number in $$prc\n" } \
		    $$build = $$1; \
		    (my $$new = $$prc) =~ s/^$(TARGET)/$(PRC_NAME)-b$$build/; \
		    system("cp $$prc $$new"); \
		    print "==> $$new\n"; \
		} \
		'

diff:
	@perl -e ' \
		my $$tag = "${tag}"; \
		if ($$tag eq "") \
		{ \
		    my @betas = sort <MaTirelire2-b*-fr.prc>; \
		    ($$tag) = ($$betas[-1] =~ /^MaTirelire2-b(\d+)/); \
		    substr($$tag, 0, 0) = "BETA_"; \
		    print "Use last found tag: $$tag\n"; \
		} \
		my @files; \
		open(DIFF, "cvs diff -r $$tag -u 2> /dev/null |"); \
		while (defined(my $$line = <DIFF>)) \
		{ \
		    if ($$line =~m;^RCS file: /home/cvsroot/MaTirelire/(.*?),v;)\
		    { push(@files, $$1); } \
		} \
		close DIFF; \
		open(LOG, "cvs log -N -S -r$${tag}:: @files |"); \
		while (defined(my $$line = <LOG>)) \
		{ \
		    unless ($$line =~ m,^(?:RCS\ file \
		    	                   |head \
		    	                   |branch \
		    	                   |locks \
		    	                   |access\ list \
		    	                   |keyword\ substitution \
		    	                   |total\ revisions \
		    	                   |description):,x) \
		    { \
		        if ($$line =~ /^Working file: (.+)/) \
		        { \
		    	    chomp; \
		    	    my $$file = $$1; \
		    	    $$file =~ s/(.)/$$1\b$$1/g; \
		    	    print $$file, "\n"; \
		        } \
		        elsif ($$line =~ /^(revision [.\d]+)$$/) \
		        { \
		    	    my $$revision = $$1; \
		    	    $$revision =~ s/(.)/_\b$$1/g; \
		    	    print $$revision, "\n"; \
		        } \
		        else \
		        { \
		    	    print $$line; \
		        } \
		    } \
		} \
		close LOG; \
		'

# Fabrique un "translation kit"
tkit:
	rm -rf $(TKIT) $(TKIT).zip
	mkdir $(TKIT)
	cp $(TKIT_TMPL)/README.txt $(TKIT_TMPL)/setup.bat $(TKIT)
	@#
	mkdir $(TKIT)/bin
	cp $(TKIT_TMPL)/bin/*.exe $(TKIT_TMPL)/bin/*.bat \
	   $(TKIT_TMPL)/bin/*.pl $(TKIT_TMPL)/bin/*.dll $(TKIT)/bin
	fgrep -v 'use strict' translate2.pl > $(TKIT)/bin/translate.pl
	@#
	mkdir $(TKIT)/samples
	cp $(ALL_RCP) $(TKIT)/samples
	perl -pi -e 's/\n/\r\n/' $(TKIT)/samples/*.rcp
	@#
	mkdir -p $(TKIT)/data/bmp
	perl -ne 'm,"(bmp/.+?\.bmp)", and print "$$1\n"' $(TARGET).rcp \
		| xargs -J % cp % $(TKIT)/data/bmp
	mkdir $(TKIT)/data/PalmResize
	cp PalmResize/resizeconsts.h $(TKIT)/data/PalmResize
	for out in obj00[0-9][0-9].out; do \
	    $(BASE)/m68k-palmos-strip -o $(TKIT)/data/$$out $$out; \
	done
	cp MaTirelireDefs.h *.obj.grc $(TKIT)/data
	echo '#include "MaTirelireDefs.h"' > $(TKIT)/data/obj.rcp
	echo '#include "MaTirelire-local.rcp"' >> $(TKIT)/data/obj.rcp
	fgrep -v '#include "' obj.rcp >> $(TKIT)/data/obj.rcp
	perl -pi -e 's/\n/\r\n/' $(TKIT)/data/MaTirelireDefs.h \
				 $(TKIT)/data/obj.rcp
	@#
	zip -9 -q -r $(TKIT).zip $(TKIT)/

tags: TAGS

TAGS:
	etags $(OBJSRC) $(CLASSESSRC) $(SRC)
