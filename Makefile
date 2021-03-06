# global makefile
# written 11/5/97 by Ue-Li Pen
#
ARCH=GENERIC  # currently relying on environment variable ARCH being set
#ARCH=$(ARCH?$(ARCH):GENERIC)
DEBUG=1
ARCHOBJS1=dlarnv.o
FC=time ifort
F90=f90
FLD=$(FC) 
# Note: if you doesn't use -r8, modify the FFT and DLARNV accordingly.
#FFLAGSB=-cpp -fdefault-real-8 #-r8
RFLAG8=-r8
FFLAGSB= -O3 $(RFLAG8) -mcmodel=medium
CPP=cpp
.SUFFIXES: .fip .fi .f .fpp .f90
# the next line needs to be commented if there it no PROJOUT and
# the files wont compile
#PROJOBJS=szmhproj.o xveucl.o wgif.o compress.o wimage.o projdm.o projphidot.o \
#	util.o squeeze.o

OBJS1=limiter.o gridtest.o multigrid.o gauss1.o mgutil.o genericfft.o \
	gfftnoopt.o relaxing.o tutil.o
OBJS=$(OBJS1)
OUTFOPT=-o 
# the fc may be overriden by the machine specific Makefile
CFLAGS=-g -ffpe-trip=invalid #$(AFLAGS) 
include Make.$(ARCH)
# add -DPROJOUT to generate gif images, etc.
CPPFLAGS=$(ARCHCPP) -DDEBUG=$(DEBUG) -DnoEXACTENERGY  -DCOLD -DNBODY #-DFIXEDGRID #-DP3M  #-DPROJOUT #-DGMETRIC -DVELDEFP
# -DFIXEDGRID prevents grid deformation
FLAGS=$(FOPTFLAGS) $(FFLAGSB)  $(MPFLAGS) 
#FFLAGS=-O -r8
#LDFLAGS=#$(FOPTFLAGS) $(MPFLAGS) 
SOURCES=Makefile Make.alpha Make.SGI Make.SX5 gauss1.fpp relaxing.fpp \
	Make.NT relaxgl.fip  cold.fip decfft.f definit.fpp \
	diffusive.fpp dimen.fh dlarnv.f drivers.fpp genericfft.f \
	globalpa.fi gmetric.fip limiter.fpp mgtemplate.fpp mgutil.fpp \
	multigrid.fpp nbody.fip radiation.fpp sgi6machine.f sgifpe_handler.c \
	stepghp.fpp COSMOPAR.DAT CHANGES README Make.KF77 sgifft.f \
	globalpa.fi90 wgif.c szmhproj.f xveucl.f90 compress.c cmap.h \
        Make.GENERIC tutil.f proj.fi projdm.f wimage.f projphidot.f util.f90 \
	squeeze.c squeeze.h hierarchic.f necfft.f gfftnoopt.f \
	POSTPROCESSING/prhopspect.f90 POSTPROCESSING/gasmap.f90 \
	POSTPROCESSING/project1.f POSTPROCESSING/project_lambda.in

relaxing.x: $(OBJS) 
	-rm relaxing.x
	$(FLD) -fpe0 $(LDFLAGS) $(OUTFOPT)$@ $(OBJS) $(LDLIBS)

run: relaxing.x
	nice -15 time ./relaxing.x

mhydro.tar.gz: mhydro.tar
	rm -f $@
	gzip mhydro.tar

mhydro.tar: $(SOURCES)
	tar cvf mhydro.tar $(SOURCES)

clean:
	-rm -f core relaxing.f mg.f gauss1.f drivers.f 
	-rm -f *.anl *.L *.m *.o *.cmp.f multigrid.f fort.* mgutil.f
	-rm -f *~ *.l *.out relaxing.x stepghp.f relaxgl.fi so_locations
	-rm -rf Z.* *_chk* prho.dat limiter.f sgenericfft.f rii_files
	-rm -rf relaxgl.fi definit.f diffusive.f gmetric.f limiter.f
	-rm -f mgtemplate.f radiation.f stepghp.f $(ARCHRM)
	-rm -f gmetric.fi $(OBJS)  *.list nbody.fi cold.fi
	-rm -f Make. gridtest.f

pps:
	pps -l fortran relaxing.fpp | multi -2 | lpr



.f90.o:
	$(F90) $(FFLAGS) -c $<


.fip.fi:
	-rm -f $@
	$(CPP) $(CPPFLAGS) $< | grep -v '^#' > $@ || rm $@
	chmod -w $@

.fpp.o:
	$(FC) $(FFLAGS) -c $<

relaxing.o: relaxgl.fi nbody.fi gmetric.fi cold.fi
drivers.f: relaxgl.fi nbody.fi cold.fi
stepghp.f: nbody.fi relaxgl.fi
relaxgl.fi: dimen.fh
multigrid.o: dimen.fh mgtemplate.fpp
mgutil.o: mgutil.fpp relaxgl.fi
definit.f: relaxgl.fi
gauss1.o: relaxgl.fi gmetric.fi
limiter.o: relaxgl.fi cold.fi
gridtest.o: relaxgl.fi 

sgenericfft.f: genericfft.f
	rm -f $@
	sed 's/subroutine f/subroutine sf/' $< > $@
	chmod -w $@

sgenericfft.o: sgenericfft.f
	$(FC) -c $<

gfftnoopt.o: gfftnoopt.f
	echo Note that gfftnoopt should not be optimized
	#$(FC) -O0 -fdefault-real-8  -g -c $<
	$(FC) -O0 $(RFLAG8)  -g -c $<

projdm.o: projdm.f nbody.fi
	$(F90) -c $(FFLAGS) $<

wimage.o: wimage.f
	$(F90) -c $(FFLAGS) $<

projphidot.o: projphidot.f proj.fi
	$(FC) -c $(FFLAGS) $<

szmhproj.o: szmhproj.f proj.fi
	$(FC) -c $(FFLAGS) $<

dlarnv.o: dlarnv.f   # needs to be reentrant for parallel code
	$(FC) -c $(FFLAGSB) $<

#Make.: Make.GENERIC
#	cp $< $@
