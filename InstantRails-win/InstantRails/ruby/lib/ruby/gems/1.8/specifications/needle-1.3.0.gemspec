Gem::Specification.new do |s|
  s.name = %q{needle}
  s.version = "1.3.0"

  s.specification_version = 1 if s.respond_to? :specification_version=

  s.required_rubygems_version = nil if s.respond_to? :required_rubygems_version=
  s.authors = ["Jamis Buck"]
  s.autorequire = %q{needle}
  s.cert_chain = nil
  s.date = %q{2005-12-24}
  s.email = %q{jamis@37signals.com}
  s.extra_rdoc_files = ["doc/README"]
  s.files = ["benchmarks/instantiability.rb", "benchmarks/instantiation.rb", "benchmarks/interceptors.rb", "benchmarks/interceptors2.rb", "doc/di-in-ruby.rdoc", "doc/faq", "doc/images", "doc/LICENSE-BSD", "doc/LICENSE-GPL", "doc/LICENSE-RUBY", "doc/manual", "doc/manual-html", "doc/README", "doc/faq/faq.rb", "doc/faq/faq.yml", "doc/images/di_classdiagram.jpg", "doc/manual/chapter.erb", "doc/manual/img", "doc/manual/index.erb", "doc/manual/manual.rb", "doc/manual/manual.yml", "doc/manual/page.erb", "doc/manual/parts", "doc/manual/stylesheets", "doc/manual/tutorial.erb", "doc/manual/img/Needle.ai", "doc/manual/img/needle.png", "doc/manual/parts/01_alternatives.txt", "doc/manual/parts/01_license.txt", "doc/manual/parts/01_support.txt", "doc/manual/parts/01_use_cases.txt", "doc/manual/parts/01_what_is_needle.txt", "doc/manual/parts/02_creating.txt", "doc/manual/parts/02_namespaces.txt", "doc/manual/parts/02_overview.txt", "doc/manual/parts/02_services.txt", "doc/manual/parts/03_conventional.txt", "doc/manual/parts/03_locator.txt", "doc/manual/parts/03_overview.txt", "doc/manual/parts/04_overview.txt", "doc/manual/parts/04_setup.txt", "doc/manual/parts/customizing_contexts.txt", "doc/manual/parts/customizing_interceptors.txt", "doc/manual/parts/customizing_namespaces.txt", "doc/manual/parts/interceptors_architecture.txt", "doc/manual/parts/interceptors_attaching.txt", "doc/manual/parts/interceptors_custom.txt", "doc/manual/parts/interceptors_ordering.txt", "doc/manual/parts/interceptors_overview.txt", "doc/manual/parts/libraries_creating.txt", "doc/manual/parts/libraries_overview.txt", "doc/manual/parts/libraries_using.txt", "doc/manual/parts/logging_configuration.txt", "doc/manual/parts/logging_logfactory.txt", "doc/manual/parts/logging_overview.txt", "doc/manual/parts/models_models.txt", "doc/manual/parts/models_overview.txt", "doc/manual/parts/models_pipelines.txt", "doc/manual/stylesheets/manual.css", "doc/manual/stylesheets/ruby.css", "doc/manual-html/chapter-1.html", "doc/manual-html/chapter-2.html", "doc/manual-html/chapter-3.html", "doc/manual-html/chapter-4.html", "doc/manual-html/chapter-5.html", "doc/manual-html/chapter-6.html", "doc/manual-html/chapter-7.html", "doc/manual-html/chapter-8.html", "doc/manual-html/chapter-9.html", "doc/manual-html/index.html", "doc/manual-html/needle.png", "doc/manual-html/stylesheets", "doc/manual-html/stylesheets/manual.css", "doc/manual-html/stylesheets/ruby.css", "lib/needle", "lib/needle.rb", "lib/needle/container.rb", "lib/needle/definition-context.rb", "lib/needle/errors.rb", "lib/needle/include-exclude.rb", "lib/needle/interceptor-chain.rb", "lib/needle/interceptor.rb", "lib/needle/lifecycle", "lib/needle/log-factory.rb", "lib/needle/logger.rb", "lib/needle/logging-interceptor.rb", "lib/needle/pipeline", "lib/needle/registry.rb", "lib/needle/service-point.rb", "lib/needle/thread.rb", "lib/needle/version.rb", "lib/needle/lifecycle/deferred.rb", "lib/needle/lifecycle/initialize.rb", "lib/needle/lifecycle/multiton.rb", "lib/needle/lifecycle/proxy.rb", "lib/needle/lifecycle/singleton.rb", "lib/needle/lifecycle/threaded.rb", "lib/needle/pipeline/collection.rb", "lib/needle/pipeline/element.rb", "lib/needle/pipeline/interceptor.rb", "test/ALL-TESTS.rb", "test/lifecycle", "test/models", "test/pipeline", "test/services.rb", "test/tc_container.rb", "test/tc_definition_context.rb", "test/tc_interceptor.rb", "test/tc_interceptor_chain.rb", "test/tc_logger.rb", "test/tc_registry.rb", "test/tc_service_point.rb", "test/lifecycle/tc_deferred.rb", "test/lifecycle/tc_initialize.rb", "test/lifecycle/tc_multiton.rb", "test/lifecycle/tc_proxy.rb", "test/lifecycle/tc_singleton.rb", "test/lifecycle/tc_threaded.rb", "test/models/model_test.rb", "test/models/tc_prototype.rb", "test/models/tc_prototype_deferred.rb", "test/models/tc_prototype_deferred_initialize.rb", "test/models/tc_prototype_initialize.rb", "test/models/tc_singleton.rb", "test/models/tc_singleton_deferred.rb", "test/models/tc_singleton_deferred_initialize.rb", "test/models/tc_singleton_initialize.rb", "test/models/tc_threaded.rb", "test/models/tc_threaded_deferred.rb", "test/models/tc_threaded_deferred_initialize.rb", "test/models/tc_threaded_initialize.rb", "test/pipeline/tc_collection.rb", "test/pipeline/tc_element.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://needle.rubyforge.org}
  s.rdoc_options = ["--title", "Needle -- Dependency Injection for Ruby", "--main", "doc/README"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new("> 0.0.0")
  s.rubygems_version = %q{1.0.1}
  s.summary = %q{Needle is a Dependency Injection/Inversion of Control container for Ruby. It supports both type-2 (setter) and type-3 (constructor) injection. It takes advantage of the dynamic nature of Ruby to provide a rich and flexible approach to injecting dependencies.}
  s.test_files = ["test/ALL-TESTS.rb"]
end
