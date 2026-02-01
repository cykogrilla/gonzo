package gonzo

import "log"

func SwallowVal[T any](val T, err error) T {
	Swallow(err)
	return val
}

func Swallow(err error) {
	if err != nil {
		log.Printf("%+v", err)
	}
}
