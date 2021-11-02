#pragma once

#include <string>

namespace greeter {
  /** Language codes to be used with the mm class */
  enum class LanguageCode { EN, ED, ES, FR };

  /**
   * @brief A class for saying hello in multiple languages
   */
  class Greeter {
    std::string _name;

  public:
    /**
     * @brief Creates a new greeter
     * @param name the name to greet
     */
    explicit Greeter(std::string name);

    /**
     * @brief Creates a localized string containing the greeting
     * @param lang the language to greet in
     * @return a string containing the greeting
     */
    std::string greet(LanguageCode lang = LanguageCode::EN) const;
  };

}  // namespace greeter