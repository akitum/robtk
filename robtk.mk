RT=$(RW)rtk/
WD=$(RW)widgets/robtk_
STRIP=strip
UNAME?=$(shell uname)

ifeq ($(UNAME),Darwin)
  OSXJACKWRAP=$(RW)jackwrap.mm
else
  OSXJACKWRAP=
endif

UITOOLKIT=$(WD)checkbutton.h $(WD)dial.h $(WD)label.h $(WD)pushbutton.h\
          $(WD)radiobutton.h $(WD)scale.h $(WD)separator.h $(WD)spinner.h \
          $(WD)xyplot.h $(WD)selector.h $(WD)multibutton.h \
          $(WD)image.h $(WD)drawingarea.h

ROBGL= $(RW)robtk.mk $(UITOOLKIT) $(RW)ui_gl.c $(PUGL_SRC) \
  $(RW)gl/common_cgl.h $(RW)gl/layout.h $(RW)gl/robwidget_gl.h $(RW)robtk.h \
	$(RT)common.h $(RT)style.h \
  $(RW)gl/xternalui.c $(RW)gl/xternalui.h

ROBGTK = $(RW)robtk.mk $(UITOOLKIT) $(RW)ui_gtk.c \
  $(RW)gtk2/common_cgtk.h $(RW)gtk2/robwidget_gtk.h $(RW)robtk.h \
	$(RT)common.h $(RT)style.h

%UI_gtk.so %UI_gtk.dylib:: $(ROBGTK)
	@mkdir -p $(@D)
	$(CXX) $(CPPFLAGS) $(CFLAGS) $(GTKUICFLAGS) \
	  -DPLUGIN_SOURCE="\"gui/$(*F).c\"" \
	  -o $@ $(RW)ui_gtk.c \
	  $(value $(*F)_UISRC) \
	  -shared $(LV2LDFLAGS) $(LDFLAGS) $(GTKUILIBS)
	$(STRIP) -x $@

%UI_gl.so %UI_gl.dylib %UI_gl.dll:: $(ROBGL)
	@mkdir -p $(@D)
	$(CXX) $(CPPFLAGS) $(CFLAGS) $(GLUICFLAGS) \
	  -DUINQHACK="$(shell date +%s$$$$)" \
	  -DPLUGIN_SOURCE="\"gui/$(*F).c\"" \
	  -o $@ $(RW)ui_gl.c \
	  $(PUGL_SRC) \
	  $(value $(*F)_UISRC) \
	  -shared $(LV2LDFLAGS) $(LDFLAGS) $(GLUILIBS)
	$(STRIP) -x $@

# ignore man-pages in rule below
x42-%.1:
	@/bin/true

x42-% x42-%.exe:: $(ROBGL) $(RW)jackwrap.c $(OSXJACKWRAP)
	@mkdir -p $(@D)
	$(CXX) $(CPPFLAGS) $(JACKCFLAGS) \
	  -DXTERNAL_UI -DHAVE_IDLE_IFACE \
	  -DPLUGIN_SOURCE="\"$(value x42_$(subst -,_,$(*F))_JACKGUI)\"" \
	  -DJACK_DESCRIPT="\"$(value x42_$(subst -,_,$(*F))_LV2HTTL)\"" \
	  -o $@ \
	  $(RW)jackwrap.c $(RW)ui_gl.c $(PUGL_SRC) $(OSXJACKWRAP) \
	  $(value x42_$(subst -,_,$(*F))_JACKSRC) \
	  $(LDFLAGS) $(JACKLIBS)
	$(STRIP) -x $@
