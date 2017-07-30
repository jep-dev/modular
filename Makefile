# .................................................................... Options
# TODO migrate options or everything but options to another makefile
builds=release
exes=modular
libs=runnable driver handler frame panel
#                                                                      build_%
build_name?=release
build_app?=$(firstword $(exes))
build_version?=0.1
#                                                                        %_dir
build_dir?=$(build_name)/
exe_dir?=$(build_dir)bin/
so_dir?=$(build_dir)lib/
d_dir?=$(build_dir)dep/
o_dir?=$(build_dir)obj/
cpp_dir?=src/
tpp_dir?=impl/
hpp_dir?=include/
#                                                                       %_dirs
inc_dirs?=$(tpp_dir) $(hpp_dir)
src_dirs?=$(cpp_dir) $(inc_dirs)
lib_dirs?=$(o_dir) $(so_dir)
# .................................................................. Overrides
flags_inc=$(inc_dirs:%=-I%)
flags_sdl=-D_REENTRANT -I/usr/include/SDL2
flags_decl=-D'BUILD="$(build_name)"' -D'VERSION=$(build_version)'
flags_d=-MT $@ -MMD -MP -MF $(d_dir)$*.Td
libs_sdl=-lSDL2_ttf -lSDL2
libs_exe=$(libs:%=-l%)
#override CXXFLAGS+=-std=c++11 $(flags_decl) $(flags_sdl)
override CXXFLAGS+=-std=c++11 $(flags_inc) $(flags_sdl)
override LDFLAGS+=$(lib_dirs:%=-L%)
override LDLIBS+=$(libs_sdl) -ldl

# ................................................................ Definitions
move_d=mv -f $(d_dir)$*.Td $(d_dir)$*.d && touch $@
#                                                                      %_files
ccomplete=.clang_complete
complete_files=$(ccomplete)
exe_files=$(exes:%=$(exe_dir)%)
so_files=$(libs:%=$(so_dir)lib%.so)
d_files=$(exes:%=$(d_dir)%.d) $(libs:%=$(d_dir)%.d)
o_files=$(exes:%=$(o_dir)%.o)
out_files=$(foreach X,exe so d o,$($(X)_files))

#......................................................................Targets
#default: $(exe_files)
default: $(exe_dir)$(build_app)
#                                                                      Compile
$(exes:%=$(o_dir)%.o): \
$(o_dir)%.o: $(cpp_dir)%.cpp $(wildcard $(hpp_dir)%.hpp) $(d_files)
	$(CXX) $(CXXFLAGS) \
		$(flags_decl) \
		$(flags_d) \
		-c $< \
		-o $@
	$(move_d)

$(libs:%=$(so_dir)%.o): \
$(so_dir)%.o: $(cpp_dir)%.cpp \
$(wildcard $(foreach X,hpp tpp,$($(X)_dir)%.$(X))) $(d_files)
	$(CXX) $(CXXFLAGS) -c -fPIC \
		$(flags_decl) \
		$(flags_d) \
		-o $@ \
		$<
	$(move_d)

#                                                                         Link
# $(libs:%=$(so_dir)lib%.so): \
# 	$(so_dir)lib%.so: $(so_dir)%.o
# 	$(CXX) $(LDFLAGS) -shared \
# 		$< \
# 		-o $@ $(LDLIBS)
# $(libs:%=$(so_dir)lib%.a): \
# 	$(CXX) $(LDFLAGS) \
# 		$< \
# 		-o $@ $(LDLIBS)
lib%.so: %.o
	$(CXX) $(LDFLAGS) -shared \
		$< \
		-o $@ $(LDLIBS)
lib%.a: %.o
	$(CXX) $(LDFLAGS) \
		$< \
		-o $@ $(LDLIBS)
# $(libs:%=$(so_dir)lib%.so): \
# $(so_dir)lib%.so: $(cpp_dir)%.cpp \
# $(wildcard $(foreach X,hpp tpp,$($(X)_dir)%.$(X))) $(d_files)
# 	$(CXX) $(CXXFLAGS) \
# 		$(flags_decl) \
# 		$(flags_d) \
# 		-fPIC $< $(LDFLAGS) \
# 		-o $@ -shared $(LDLIBS)
# 	$(move_d)

$(exes:%=$(exe_dir)%): \
$(exe_dir)%: $(o_dir)%.o $(so_files) $(o_files)
	$(eval build_app:=$(@:$(o_dir)%=%))
	$(CXX) $(LDFLAGS) \
		-Wl,-rpath,$(o_dir):$(so_dir):$(so_o_dir) \
		-o $@ $< \
		$(libs:%=-l%) $(LDLIBS)
#............................................................. Special targets
#                                                               Clang Complete
$(ccomplete): $(d_files); @echo $(CXXFLAGS) > $@
.PRECIOUS: $(complete_files)
#                                                                  Print value
print-val-%:; @echo "$*"
#                                                     Print variable and value
print-var-%:; @echo "'$*' = '$($*)'"
#                                                               Print includes
# Does not appear to show included dependency files
print-includes: print-var-MAKEFILE_LIST
.PHONY: echo-% print-%

#                                                                      clean-%
clean-o:; rm -f $(o_files)
clean-d:; rm -f $(d_files)
clean-so:; rm -f $(so_files)
clean-exe:; rm -f $(exe_files)
clean: clean-o clean-d clean-so clean-exe
.PHONY: clean $(foreach T,o d so exe,clean-$(T))

#                                                             Precious targets
.PRECIOUS: $(d_dir)%.d .clang_complete
$(d_dir)%.d:;

#........................................................ Dependency inclusion
include $(wildcard $($(libs) $(exes):%=release/dep/%.d))
include $(wildcard Doxygen.mk)
