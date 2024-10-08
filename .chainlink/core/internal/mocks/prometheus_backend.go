// Code generated by mockery v2.43.2. DO NOT EDIT.

package mocks

import (
	big "math/big"

	mock "github.com/stretchr/testify/mock"
)

// PrometheusBackend is an autogenerated mock type for the PrometheusBackend type
type PrometheusBackend struct {
	mock.Mock
}

type PrometheusBackend_Expecter struct {
	mock *mock.Mock
}

func (_m *PrometheusBackend) EXPECT() *PrometheusBackend_Expecter {
	return &PrometheusBackend_Expecter{mock: &_m.Mock}
}

// SetMaxUnconfirmedAge provides a mock function with given fields: _a0, _a1
func (_m *PrometheusBackend) SetMaxUnconfirmedAge(_a0 *big.Int, _a1 float64) {
	_m.Called(_a0, _a1)
}

// PrometheusBackend_SetMaxUnconfirmedAge_Call is a *mock.Call that shadows Run/Return methods with type explicit version for method 'SetMaxUnconfirmedAge'
type PrometheusBackend_SetMaxUnconfirmedAge_Call struct {
	*mock.Call
}

// SetMaxUnconfirmedAge is a helper method to define mock.On call
//   - _a0 *big.Int
//   - _a1 float64
func (_e *PrometheusBackend_Expecter) SetMaxUnconfirmedAge(_a0 interface{}, _a1 interface{}) *PrometheusBackend_SetMaxUnconfirmedAge_Call {
	return &PrometheusBackend_SetMaxUnconfirmedAge_Call{Call: _e.mock.On("SetMaxUnconfirmedAge", _a0, _a1)}
}

func (_c *PrometheusBackend_SetMaxUnconfirmedAge_Call) Run(run func(_a0 *big.Int, _a1 float64)) *PrometheusBackend_SetMaxUnconfirmedAge_Call {
	_c.Call.Run(func(args mock.Arguments) {
		run(args[0].(*big.Int), args[1].(float64))
	})
	return _c
}

func (_c *PrometheusBackend_SetMaxUnconfirmedAge_Call) Return() *PrometheusBackend_SetMaxUnconfirmedAge_Call {
	_c.Call.Return()
	return _c
}

func (_c *PrometheusBackend_SetMaxUnconfirmedAge_Call) RunAndReturn(run func(*big.Int, float64)) *PrometheusBackend_SetMaxUnconfirmedAge_Call {
	_c.Call.Return(run)
	return _c
}

// SetMaxUnconfirmedBlocks provides a mock function with given fields: _a0, _a1
func (_m *PrometheusBackend) SetMaxUnconfirmedBlocks(_a0 *big.Int, _a1 int64) {
	_m.Called(_a0, _a1)
}

// PrometheusBackend_SetMaxUnconfirmedBlocks_Call is a *mock.Call that shadows Run/Return methods with type explicit version for method 'SetMaxUnconfirmedBlocks'
type PrometheusBackend_SetMaxUnconfirmedBlocks_Call struct {
	*mock.Call
}

// SetMaxUnconfirmedBlocks is a helper method to define mock.On call
//   - _a0 *big.Int
//   - _a1 int64
func (_e *PrometheusBackend_Expecter) SetMaxUnconfirmedBlocks(_a0 interface{}, _a1 interface{}) *PrometheusBackend_SetMaxUnconfirmedBlocks_Call {
	return &PrometheusBackend_SetMaxUnconfirmedBlocks_Call{Call: _e.mock.On("SetMaxUnconfirmedBlocks", _a0, _a1)}
}

func (_c *PrometheusBackend_SetMaxUnconfirmedBlocks_Call) Run(run func(_a0 *big.Int, _a1 int64)) *PrometheusBackend_SetMaxUnconfirmedBlocks_Call {
	_c.Call.Run(func(args mock.Arguments) {
		run(args[0].(*big.Int), args[1].(int64))
	})
	return _c
}

func (_c *PrometheusBackend_SetMaxUnconfirmedBlocks_Call) Return() *PrometheusBackend_SetMaxUnconfirmedBlocks_Call {
	_c.Call.Return()
	return _c
}

func (_c *PrometheusBackend_SetMaxUnconfirmedBlocks_Call) RunAndReturn(run func(*big.Int, int64)) *PrometheusBackend_SetMaxUnconfirmedBlocks_Call {
	_c.Call.Return(run)
	return _c
}

// SetPipelineRunsQueued provides a mock function with given fields: n
func (_m *PrometheusBackend) SetPipelineRunsQueued(n int) {
	_m.Called(n)
}

// PrometheusBackend_SetPipelineRunsQueued_Call is a *mock.Call that shadows Run/Return methods with type explicit version for method 'SetPipelineRunsQueued'
type PrometheusBackend_SetPipelineRunsQueued_Call struct {
	*mock.Call
}

// SetPipelineRunsQueued is a helper method to define mock.On call
//   - n int
func (_e *PrometheusBackend_Expecter) SetPipelineRunsQueued(n interface{}) *PrometheusBackend_SetPipelineRunsQueued_Call {
	return &PrometheusBackend_SetPipelineRunsQueued_Call{Call: _e.mock.On("SetPipelineRunsQueued", n)}
}

func (_c *PrometheusBackend_SetPipelineRunsQueued_Call) Run(run func(n int)) *PrometheusBackend_SetPipelineRunsQueued_Call {
	_c.Call.Run(func(args mock.Arguments) {
		run(args[0].(int))
	})
	return _c
}

func (_c *PrometheusBackend_SetPipelineRunsQueued_Call) Return() *PrometheusBackend_SetPipelineRunsQueued_Call {
	_c.Call.Return()
	return _c
}

func (_c *PrometheusBackend_SetPipelineRunsQueued_Call) RunAndReturn(run func(int)) *PrometheusBackend_SetPipelineRunsQueued_Call {
	_c.Call.Return(run)
	return _c
}

// SetPipelineTaskRunsQueued provides a mock function with given fields: n
func (_m *PrometheusBackend) SetPipelineTaskRunsQueued(n int) {
	_m.Called(n)
}

// PrometheusBackend_SetPipelineTaskRunsQueued_Call is a *mock.Call that shadows Run/Return methods with type explicit version for method 'SetPipelineTaskRunsQueued'
type PrometheusBackend_SetPipelineTaskRunsQueued_Call struct {
	*mock.Call
}

// SetPipelineTaskRunsQueued is a helper method to define mock.On call
//   - n int
func (_e *PrometheusBackend_Expecter) SetPipelineTaskRunsQueued(n interface{}) *PrometheusBackend_SetPipelineTaskRunsQueued_Call {
	return &PrometheusBackend_SetPipelineTaskRunsQueued_Call{Call: _e.mock.On("SetPipelineTaskRunsQueued", n)}
}

func (_c *PrometheusBackend_SetPipelineTaskRunsQueued_Call) Run(run func(n int)) *PrometheusBackend_SetPipelineTaskRunsQueued_Call {
	_c.Call.Run(func(args mock.Arguments) {
		run(args[0].(int))
	})
	return _c
}

func (_c *PrometheusBackend_SetPipelineTaskRunsQueued_Call) Return() *PrometheusBackend_SetPipelineTaskRunsQueued_Call {
	_c.Call.Return()
	return _c
}

func (_c *PrometheusBackend_SetPipelineTaskRunsQueued_Call) RunAndReturn(run func(int)) *PrometheusBackend_SetPipelineTaskRunsQueued_Call {
	_c.Call.Return(run)
	return _c
}

// SetUnconfirmedTransactions provides a mock function with given fields: _a0, _a1
func (_m *PrometheusBackend) SetUnconfirmedTransactions(_a0 *big.Int, _a1 int64) {
	_m.Called(_a0, _a1)
}

// PrometheusBackend_SetUnconfirmedTransactions_Call is a *mock.Call that shadows Run/Return methods with type explicit version for method 'SetUnconfirmedTransactions'
type PrometheusBackend_SetUnconfirmedTransactions_Call struct {
	*mock.Call
}

// SetUnconfirmedTransactions is a helper method to define mock.On call
//   - _a0 *big.Int
//   - _a1 int64
func (_e *PrometheusBackend_Expecter) SetUnconfirmedTransactions(_a0 interface{}, _a1 interface{}) *PrometheusBackend_SetUnconfirmedTransactions_Call {
	return &PrometheusBackend_SetUnconfirmedTransactions_Call{Call: _e.mock.On("SetUnconfirmedTransactions", _a0, _a1)}
}

func (_c *PrometheusBackend_SetUnconfirmedTransactions_Call) Run(run func(_a0 *big.Int, _a1 int64)) *PrometheusBackend_SetUnconfirmedTransactions_Call {
	_c.Call.Run(func(args mock.Arguments) {
		run(args[0].(*big.Int), args[1].(int64))
	})
	return _c
}

func (_c *PrometheusBackend_SetUnconfirmedTransactions_Call) Return() *PrometheusBackend_SetUnconfirmedTransactions_Call {
	_c.Call.Return()
	return _c
}

func (_c *PrometheusBackend_SetUnconfirmedTransactions_Call) RunAndReturn(run func(*big.Int, int64)) *PrometheusBackend_SetUnconfirmedTransactions_Call {
	_c.Call.Return(run)
	return _c
}

// NewPrometheusBackend creates a new instance of PrometheusBackend. It also registers a testing interface on the mock and a cleanup function to assert the mocks expectations.
// The first argument is typically a *testing.T value.
func NewPrometheusBackend(t interface {
	mock.TestingT
	Cleanup(func())
}) *PrometheusBackend {
	mock := &PrometheusBackend{}
	mock.Mock.Test(t)

	t.Cleanup(func() { mock.AssertExpectations(t) })

	return mock
}
