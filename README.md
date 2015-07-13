# php-composer-completion package
autocomplete+ provider for php projects based on composer.

This package is currently under development and might not work properly with others php providers.

# How it works
The package searches for the vendor/autoload.php file within the project root and uses it to resolve the methods available in some given class on your project.

Currently the features provided are:

- Method resolution for the current class (i.e. $this->).
- Method resolution for any dependency set as a method parameter, so if your method parameter relies on an interface, or a class the methods will pop up when you try to call it within that method.
- Correct resolution for static methods
- Support for self and parent keywords
- Variables and constants
- Inherited methods

# todo
This is an experimental package yet and there are a lot of features missing, the ones I'm planning to the next beta release are:
- Resolution for explicit property attribution via constructor
- Access to static resources for a given class name
- Methods from interfaces

# bugs
If you find any bugs, or have any proposal please feel free to open an issue and I'll try to help as soon as possible.

![A screenshot of your package](https://f.cloud.github.com/assets/69169/2290250/c35d867a-a017-11e3-86be-cd7c5bf3ff9b.gif)
