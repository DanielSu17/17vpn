package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestCheckDiff(t *testing.T) {
	cases := []struct {
		name, removed, added string
		expected             []string
	}{
		// no params
		{
			`no params`,
			`"key1": "oldval1"
		     "key2": "oldval2"`,
			`"key1": "newval1"
		     "key2": "newval2"`,
			[]string{},
		},
		// IOS same count
		{
			`IOS same count`,
			`"key1": "oldval1%1$@"
		     "key2": "oldval2"`,
			`"key1": "newval1%1$@"
		     "key2": "newval2"`,
			[]string{},
		},
		// IOS new key
		{
			`IOS new key`,
			`"key1": "oldval1"`,
			`"key1": "newval1"
		     "key2": "newval2%1$@"`,
			[]string{},
		},
		// IOS remove key
		{
			`IOS remove key`,
			`"key1": "oldval1%1$@"
		     "key2": "newval2"`,
			`"key2": "newval2"`,
			[]string{},
		},
		// IOS 2 params -> 1 param
		{
			`IOS 2 params -> 1 param`,
			`"key1": "oldval1%1$@,%2$@"`,
			`"key1": "newval1%1$@"`,
			[]string{"key1"},
		},
		// IOS 1 param -> 2 params
		{
			`IOS 1 param -> 2 params`,
			`"key1": "newval1%1$@"`,
			`"key1": "oldval1%1$@,%2$@"`,
			[]string{"key1"},
		},
		// Android same count
		{
			`Android same count`,
			`"key1": "oldval1%1$s"
		     "key2": "oldval2"`,
			`"key1": "newval1%1$s"
		     "key2": "newval2"`,
			[]string{},
		},
		// Android new key
		{
			`Android new key`,
			`"key1": "oldval1"`,
			`"key1": "newval1"
		     "key2": "newval2%1$s"`,
			[]string{},
		},
		// Android remove key
		{
			`Android remove key`,
			`"key1": "oldval1%1$s"
		     "key2": "newval2"`,
			`"key2": "newval2"`,
			[]string{},
		},
		// Android 2 params -> 1 param
		{
			`Android 2 params -> 1 param`,
			`"key1": "oldval1%1$s,%2$s"`,
			`"key1": "newval1%1$s"`,
			[]string{"key1"},
		},
		// Android 1 param -> 2 params
		{
			`Android 1 param -> 2 params`,
			`"key1": "newval1%1$s"`,
			`"key1": "oldval1%1$s,%2$s"`,
			[]string{"key1"},
		},
		// Backend same count
		{
			`Backend same count`,
			`"key1": "oldval1$1"
		     "key2": "oldval2"`,
			`"key1": "newval1$1"
		     "key2": "newval2"`,
			[]string{},
		},
		// Backend new key
		{
			`Backend new key`,
			`"key1": "oldval1"`,
			`"key1": "newval1"
		     "key2": "newval2$1"`,
			[]string{},
		},
		// Backend remove key
		{
			`Backend remove key`,
			`"key1": "oldval1$1"
		     "key2": "newval2"`,
			`"key2": "newval2"`,
			[]string{},
		},
		// Backend 2 params -> 1 param
		{
			`Backend 2 params -> 1 param`,
			`"key1": "oldval1$1,$2"`,
			`"key1": "newval1$1"`,
			[]string{"key1"},
		},
		// Backend 1 param -> 2 params
		{
			`Backend 1 param -> 2 params`,
			`"key1": "newval1$1"`,
			`"key1": "oldval1$1,$2"`,
			[]string{"key1"},
		},
	}
	for _, c := range cases {
		o := checkDiff(c.removed, c.added)
		assert.Equal(t, c.expected, o, c.name)
	}
}
