require 'formula'

class Vtk < Formula
  url 'http://www.vtk.org/files/release/5.6/vtk-5.6.1.tar.gz'
  homepage 'http://www.vtk.org'
  md5 'b80a76435207c5d0f74dfcab15b75181'

  depends_on 'cmake' => :build
  depends_on 'qt' if ARGV.include? '--qt'

  def options
  [
    ['--python', "Enable python wrapping."],
    ['--qt', "Enable Qt extension."],
    ['--qt-extern', "Enable Qt extension (via external Qt)"],
    ['--tcl', "Enable Tcl wrapping."],
  ]
  end

  def patches
    # fixes compilation issue on Mac OS X 10.7
    "http://vtk.org/gitweb?p=VTK.git;a=patch;h=70db254a59c18a5e565c3232813dc821bb337563;hp=0c5990f503fe8f6e5f1a07b85b804dcc4262a6ed"
  end

  def install
    args = std_cmake_parameters.split + [
             "-DVTK_REQUIRED_OBJCXX_FLAGS:STRING=''",
             "-DVTK_USE_CARBON:BOOL=OFF",
             "-DVTK_USE_COCOA:BOOL=ON",
             "-DBUILD_TESTING:BOOL=OFF",
             "-DBUILD_EXAMPLES:BOOL=OFF",
             "-DBUILD_SHARED_LIBS:BOOL=ON",
             "-DCMAKE_INSTALL_RPATH:STRING='#{lib}/vtk-5.6'",
             "-DCMAKE_INSTALL_NAME_DIR:STRING='#{lib}/vtk-5.6'"]

    if ARGV.include? '--python'
      python_prefix = `python-config --prefix`.strip
      # Install to global python site-packages
      args << "-DVTK_PYTHON_SETUP_ARGS:STRING='--prefix=#{python_prefix}'"
      # Python is actually a library. The libpythonX.Y.dylib points to this lib, too.
      if File.exist? "#{python_prefix}/Python"
        # Python was compiled with --framework:
        args << "-DPYTHON_LIBRARY='#{python_prefix}/Python'"
      else
        python_version = `python-config --libs`.match('-lpython(\d+\.\d+)').captures.at(0)
        python_lib = "#{python_prefix}/lib/libpython#{python_version}"
        if File.exists? "#{python_lib}.a"
          args << "-DPYTHON_LIBRARY='#{python_lib}.a'"
        else
          args << "-DPYTHON_LIBRARY='#{python_lib}.dylib'"
        end
      end
      args << "-DVTK_WRAP_PYTHON:BOOL=ON"
    end

    if ARGV.include? '--qt' or ARGV.include? '--qt-extern'
      args << "-DVTK_USE_GUISUPPORT:BOOL=ON"
      args << "-DVTK_USE_QT:BOOL=ON"
      args << "-DVTK_USE_QVTK:BOOL=ON"
    end

    if ARGV.include? '--tcl'
      args << "-DVTK_WRAP_TCL:BOOL=ON"
    end

    # Hack suggested at http://www.vtk.org/pipermail/vtk-developers/2006-February/003983.html
    # to get the right RPATH in the python libraries (the .so files in the vtk egg).
    # Also readable: http://vtk.1045678.n5.nabble.com/VTK-Python-Wrappers-on-Red-Hat-td1246159.html
    args << "-DCMAKE_BUILD_WITH_INSTALL_RPATH:BOOL=ON"
    ENV['DYLD_LIBRARY_PATH'] = `pwd`.strip + "/build/bin"

    system "mkdir build"
    args << ".."
    Dir.chdir 'build' do
      system "cmake", *args
      system "make install"
    end
  end
end
