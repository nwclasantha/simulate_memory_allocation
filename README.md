This Perl script is refactored to use object-oriented programming (OOP) principles. It allocates memory on the system based on user input and provides options to either allocate a specific number of megabytes (MB) or a percentage of the total system memory. The script is organized into a class structure to improve modularity and maintainability. Below is a detailed explanation of each part of the script.

![JQnkiZXC2BpyidoyXuTbSS](https://github.com/user-attachments/assets/f0e71913-621e-4380-8e92-2fa29964d680)

### 1. **Logging Setup**:
```perl
use Log::Log4perl;
use Try::Tiny;
```
- **`Log::Log4perl`**: This module is used to log information, warnings, and errors. The log messages are sent to both the console (screen) and a log file (`script.log`).
- **`Try::Tiny`**: This module provides `try/catch` blocks for error handling. It allows catching exceptions that may occur during file operations or memory management.

#### Logger Initialization:
```perl
Log::Log4perl->init(\ <<'EOT');
...
EOT
```
- This block sets up two logging appenders: one to write logs to a file (`script.log`), and another to print logs on the screen. The logging format includes timestamps, log levels (INFO, ERROR), and messages.

### 2. **`MemoryManager` Class**:
The core of this script is encapsulated inside the `MemoryManager` class, which is responsible for calculating and managing memory allocation.

#### Constructor:
```perl
sub new {
    my ($class) = @_;
    my $self = {};
    bless $self, $class;
    return $self;
}
```
- **`new`**: This is the class constructor. It initializes a new `MemoryManager` object. `bless` ties the object to the class, making it an instance of `MemoryManager`.

#### `find_memto_occupy` Method:
```perl
sub find_memto_occupy {
    my ($self, $pc) = @_;
    ...
}
```
- **Purpose**: This method takes a percentage (`$pc`) as input and calculates the amount of memory to allocate based on the total available system memory.
- **Logic**:
  - It opens the `/proc/meminfo` file (available on Linux systems), reads the total memory, and calculates the percentage of memory the user wants to occupy.
  - If the memory is successfully calculated, it converts it from kilobytes (KB) to megabytes (MB) and returns the value.
  - If any error occurs (e.g., the percentage is invalid or `/proc/meminfo` cannot be opened), it logs the error and throws an exception.

#### `allocate_memory` Method:
```perl
sub allocate_memory {
    my ($self, $mb) = @_;
    ...
}
```
- **Purpose**: This method allocates a specified amount of memory (in MB).
- **Logic**:
  - It calculates the number of bytes to allocate by multiplying the MB value by `1024 * 1024`.
  - It then opens a filehandle to an in-memory scalar variable (`$memory`) and writes a large block of null bytes (`chr(0)`) to simulate memory allocation.
  - The memory is "allocated" by maintaining a reference to this in-memory filehandle.
  - If any error occurs during allocation, it logs the error and throws an exception.

#### `release_memory` Method:
```perl
sub release_memory {
    my ($self, $memory_ref) = @_;
    undef $$memory_ref;
}
```
- **Purpose**: This method releases the memory by undefining the in-memory scalar that was holding the allocated data.
- **Logic**:
  - The method takes a reference to the memory (scalar variable) as input.
  - By using `undef`, it frees the memory previously allocated, and a log message confirms that memory has been released.

### 3. **Main Program Logic**:
The main logic of the script resides in the `main` package (standard in Perl scripts).

#### Input Validation:
```perl
my $num = shift @ARGV;
unless (defined $num && $num =~ /^\d+%?$/) {
    ...
}
```
- **Purpose**: This checks the user input, which should be either a percentage (e.g., `50%`) or a number of megabytes (e.g., `100`).
- **Logic**:
  - It expects a single command-line argument (`$num`), which can either be a percentage or an integer value in MB.
  - If the input doesn't match the expected format, it throws an error.

#### Creating the `MemoryManager` Object:
```perl
my $mem_manager = MemoryManager->new();
```
- A new instance of `MemoryManager` is created using the `new` constructor. This object will handle memory operations (finding and allocating memory).

#### Memory Calculation:
```perl
if ($num =~ /^(\d+)%$/) {
    my $pc = $1;
    $mb = $mem_manager->find_memto_occupy($pc);
} else {
    $mb = $num;
}
```
- **Purpose**: This block checks whether the user provided a percentage (`50%`) or a fixed number of MB (`100`).
- **Logic**:
  - If the input is a percentage, the `find_memto_occupy` method is called to calculate the MB to occupy.
  - Otherwise, it treats the input as an absolute number of megabytes.

#### Memory Allocation:
```perl
my $memory = $mem_manager->allocate_memory($mb);
```
- **Purpose**: This line calls the `allocate_memory` method to allocate the calculated amount of memory.
- **Logic**:
  - The `$memory` variable holds a reference to the in-memory scalar, which prevents Perl from automatically freeing the allocated memory.

#### Releasing Memory:
```perl
<STDIN>;
$mem_manager->release_memory(\$memory);
```
- **Purpose**: The program waits for the user to press ENTER to release the memory.
- **Logic**:
  - The memory is released by passing a reference to `$memory` to the `release_memory` method, which undefines the memory.

### 4. **Error Handling and Logging**:
Throughout the script, **error handling** and **logging** are integrated into every step using `try/catch` blocks and the `Log::Log4perl` logger.

- **Logging**:
  - Logs are generated at various levels (INFO, ERROR) to track the script's execution.
  - If any operation (e.g., reading `/proc/meminfo`, allocating memory) fails, the script logs an error message and terminates with a helpful message for the user.
  
- **Exception Handling**:
  - `Try::Tiny` provides the `try/catch` mechanism to capture and handle errors in a controlled way, ensuring that the script doesn't crash unexpectedly.

### 5. **Example Command-line Usage**:
- **To occupy 100 MB of memory**:
  ```bash
  perl script.pl 100
  ```
  The script will occupy 100 MB of memory until the user presses ENTER.

- **To occupy 50% of the total available memory**:
  ```bash
  perl script.pl 50%
  ```

### Conclusion:
This refactored script demonstrates how to use Perl's OOP capabilities to encapsulate logic into a `MemoryManager` class, making the script modular and easy to extend. Logging and error handling ensure robustness and traceability during execution. It calculates memory, allocates it, and then releases it based on user input.
