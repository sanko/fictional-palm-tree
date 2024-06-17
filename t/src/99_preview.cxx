// Basic
void test(int a) {
    return;
}
int negative(int a) {
    return -a;
}

// Class example
#include <iostream>

class Person
{
  public:
    Person(std::string name, int age) : name(name), age(age) {}
    std::string getName() const { return name; }

    int getAge() const { return age; }

    void introduce() const {
        std::cout << "Hello, my name is " << name << " and I am " << age << " years old."
                  << std::endl;
    }

  private:
    std::string name;
    int age;
};

Person getobj(const char *name, int age) {
    Person person(name, age);
    person.introduce(); // Output: Hello, my name is Alice and I am 30 years old.
    return person;
}
