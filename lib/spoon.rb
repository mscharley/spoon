require 'ffi'

module Spoon
  extend FFI::Library
  
  # int
  # posix_spawn(pid_t *restrict pid, const char *restrict path,
  #     const posix_spawn_file_actions_t *file_actions,
  #     const posix_spawnattr_t *restrict attrp, char *const argv[restrict],
  #     char *const envp[restrict]);
  
  begin
    ffi_lib 'c'
    
    attach_function :_posix_spawn, :posix_spawn, [:pointer, :string, :pointer, :pointer, :pointer, :pointer], :int
    attach_function :_posix_spawnp, :posix_spawnp, [:pointer, :string, :pointer, :pointer, :pointer, :pointer], :int
  rescue FFI::NotFoundError
  end
  
  # BOOL WINAPI CreateProcess(
  #   __in_opt     LPCTSTR lpApplicationName,
  #   __inout_opt  LPTSTR lpCommandLine,
  #   __in_opt     LPSECURITY_ATTRIBUTES lpProcessAttributes,
  #   __in_opt     LPSECURITY_ATTRIBUTES lpThreadAttributes,
  #   __in         BOOL bInheritHandles,
  #   __in         DWORD dwCreationFlags,
  #   __in_opt     LPVOID lpEnvironment,
  #   __in_opt     LPCTSTR lpCurrentDirectory,
  #   __in         LPSTARTUPINFO lpStartupInfo,
  #   __out        LPPROCESS_INFORMATION lpProcessInformation
  # );
  
  begin
    ffi_lib 'kernel32'
    ffi_convention :stdcall
    
    attach_function :_create_process, :CreateProcessW, [:buffer_in, :pointer, :pointer, :pointer, :int, :int, :pointer, :buffer_in, :pointer, :pointer], :int
    
    class SecurityAttributes < FFI::Struct
      layout :length, :int,                   # DWORD
             :security_descriptor, :pointer,  # LPVOID
             :inherit_handler, :int           # BOOL
    end
    
    class StartupInfo < FFI:Struct
      
    end
    
    class ProcessInformation < FFI:Struct
      
    end
  rescue FFI::NotFoundError
  end
  
  def self.have_spawn?
    begin
      self.method(:_posix_spawn)
    rescue NameError
      false
    end
  end
  
  def self.have_create_process?
    begin
      self.method(:_create_process)
    rescue NameError
      false
    end
  end
  
  def self.supported?
    have_spawn? or have_create_process?
  end
  
  def self.spawn(*args)
    if have_spawn?
      spawn_spawn(*args)
    else
      spawn_cp(*args)
    end
  end

  def self.spawnp(*args)
    if have_spawn?
      spawnp_spawn(*args)
    else
      spawnp_cp(*args)
    end
  end
  
  private
  
  def self.spawn_spawn(*args)
    spawn_args = _prepare_spawn_args(args)
    _posix_spawn(*spawn_args)
    spawn_args[0].read_int
  end
  
  def self.spawn_cp(*args)
    
  end
  
  def self.spawnp_spawn(*args)
    spawn_args = _prepare_spawn_args(args)
    _posix_spawnp(*spawn_args)
    spawn_args[0].read_int
  end
  
  def self.spawnp_cp(*args)
    
  end
  
  def self._prepare_spawn_args(args)
    pid_ptr = FFI::MemoryPointer.new(:pid_t, 1)

    args_ary = FFI::MemoryPointer.new(:pointer, args.length + 1)
    str_ptrs = args.map {|str| FFI::MemoryPointer.from_string(str)}
    args_ary.put_array_of_pointer(0, str_ptrs)

    env_ary = FFI::MemoryPointer.new(:pointer, ENV.length + 1)
    env_ptrs = ENV.map {|key,value| FFI::MemoryPointer.from_string("#{key}=#{value}")}
    env_ary.put_array_of_pointer(0, env_ptrs)
    
    [pid_ptr, args[0], nil, nil, args_ary, env_ary]
  end
end

if __FILE__ == $0
  pid = Spoon.spawn('/usr/bin/vim')

  Process.waitpid(pid)
end
