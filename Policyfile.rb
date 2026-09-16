name 'limits_test'
run_list 'limits_test'

cookbook 'limits', path: '.'
cookbook 'limits_test', path: './test/fixtures/cookbooks/limits_test'
