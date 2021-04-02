// This is the source of truth for the DESIRED STATE of the dagger command-line user interface (UI)
//
// - The CLI implementation is written manually, using this document as a spec. If you spot
//   a discrepancy between the spec and implementation, please report it or even better,
//   submit a patch to the implementation.
//
// - To propose changes to the UI, submit a patch to this spec. Patches to the CLI implementation
//   which don't match the spec will be rejected.
//
// - It is OK to propose changes to the CLI spec before an implementation is ready. To speed up
//   development, we tolerate a lag between the spec and implementation. This may change in the
//   future once the project is more mature.

package spec

import (
	"text/tabwriter"
)

// Examples:
//
// cue eval --out text
// cue eval --out text -e '#Dagger.command.query.usage'
#Dagger.usage

#Dagger: #Command & {

	name:        "dagger"
	description: "Write code to deploy your code"

	doc: """
		A Dagger deployment is a continuously running workflow delivering a specific application in a specific way.

		The same application can be delivered via different deployments, each with a different configuration.
		For example a production deployment might include manual validation and addition performance testing,
		while a staging deployment might automatically deploy from a git branch, load test data into the database,
		and run on a separate cluster.

		A deployment is made of 3 parts: a deployment plan, inputs, and outputs.
		"""

	flag: {
		"--deployment": {
			alt:         "-d"
			description:
				"""
				Select a deployment

				If no deployment is specified, dagger searches for deployments using the current
				directory as input.

				* If exactly one deployment matches the search, it is selected.
				* If there is more than one match, the user is prompted to select one.
				* If there is no match, the command returns an error.
				"""
			arg:         "NAME"
		}
		"--log-format": {
			arg:         "string"
			description: "Log format (json, pretty). Defaults to json if the terminal is not a tty"
		}
		"--log-level": {
			alt:         "-l"
			arg:         "string"
			description: "Log level"
			default:     "debug"
		}
	}

	command: {
		new: {
			description: "Create a new deployment"
			flag: {
				"--name": {
					alt:         "-n"
					description: "Specify a deployment name"
					default:     "name of current directory"
				}

				"--plan-dir": description: "Load deployment plan from a local directory"

				"--plan-git": description: "Load deployment plan from a git repository"

				"--plan-package": description: "Load deployment plan from a cue package"

				"--plan-file": description: "Load deployment plan from a cue or json file"

				"--up": {
					alt:         "-u"
					description: "Bring the deployment online"
				}

				"--setup": {
					arg:         "no|yes|auto"
					description: "Specify whether to prompt user for initial setup"
				}
			}
		}

		list: description: "List available deployments"

		query: {
			arg:         "[EXPR] [flags]"
			description: "Query the contents of a deployment"
			doc:
				"""
					EXPR may be any valid CUE expression. The expression is evaluated against the deployment contents. The deployment is not changed.
					Examples:

					  # Print the entire deployment plan with inputs merged in (but no outputs)
					  $ dagger query --no-output

					  # Print the deployment plan, inputs and outputs of a particular step
					  $ dagger query www.build

					  # Print the URL of a deployed service
					  $ dagger query api.url

					  # Export environment variables from a deployment
					  $ dagger query -f json api.environment

					"""

			flag: {

				// FIXME: confusing flag choice?
				// Use --revision or --change or --change-id instead?
				"--version": {
					alt:         "-v"
					description: "Query a specific version of the deployment"
					default:     "latest"
				}

				"--format": {
					alt:         "-f"
					description: "Output format"
					arg:         "json|yaml|cue|text|env"
				}

				"--no-input": {
					alt:         "-I"
					description: "Exclude inputs from query"
				}
				"--no-output": {
					alt:         "-O"
					description: "Exclude outputs from query"
				}
				"--no-plan": {
					alt:         "-L"
					description: "Exclude deployment plan from query"
				}
			}
		}

		up: {
			description: "Bring a deployment online with latest deployment plan and inputs"
			flag: "--no-cache": description: "Disable all run cache"
		}

		down: {
			description: "Take a deployment offline (WARNING: may destroy infrastructure)"
			flag: "--no-cache": description: "Disable all run cache"
		}

		history: description: "List past changes to a deployment"

		delete: {
			description: "Delete a deployment after taking it offline (WARNING: may destroy infrastructure)"
		}

		plan: {
			description: "Manage a deployment plan"

			command: {
				package: {
					description: "Load plan from a cue package"
					arg:         "PKG"
					doc:
						"""
						Examples:
						  dagger plan package dagger.io/templates/jamstack
						"""
				}

				dir: {
					description: "Load plan from a local directory"
					arg:         "PATH"
					doc:
						"""
						Examples:
						  dagger plan dir ./infra/prod
						"""
				}

				git: {
					description: "Load plan from a git repository"
					arg:         "REMOTE REF [SUBDIR]"
					doc:
						"""
						Examples:
						  dagger plan git https://github.com/dagger/dagger main examples/simple
						"""
				}

				file: {
					description: "Load plan from a cue file"
					arg:         "PATH|-"
					doc:
						"""
						Examples:
						  dagger plan file ./myapp-staging.cue
						  echo 'message: "hello, \(name)!", name: string | *"world"' | dagger plan file -
						"""
				}
			}
		}

		input: {
			description: "Manage a deployment's inputs"

			command: {
				// FIXME: details of individual input commands
				dir: {description: "Add a local directory as input artifact"}
				git: description:       "Add a git repository as input artifact"
				container: description: "Add a container image as input artifact"
				value: description:     "Add an input value"
				secret: description:    "Add an encrypted input secret"
			}
		}

		output: {
			description: "Manage a deployment's outputs"
			// FIXME: bind output values or artifacts
			// to local dir or file
			// BONUS: bind a deployment output to another deployment's input?
		}

		login: description: "Login to Dagger Cloud"

		logout: description: "Logout from Dagger Cloud"
	}
}

#Command: {
	// Command name
	name: string

	description: string
	doc:         string | *""

	// Flags
	flag: [fl=string]: #Flag & {name: fl}
	flag: "--help": {
		alt:         "-h"
		description: "help for \(name)"
	}

	// Sub-commands
	command: [cmd=string]: #Command & {
		name: cmd
	}

	arg: string | *"[command]"

	usage: {
		"""
		\(description)
		\(doc)

		Usage:
		  \(name) \(arg)

		Available commands:
		\(tabwriter.Write(#commands))
		
		Flags:
		\(tabwriter.Write(#flags))
		"""

		#commands: [ for name, cmd in command {
			"""
			  \(name)\t\(cmd.description)
			"""
		}]
		#flags: [ for name, fl in flag {
			"""
			  \(name), \(fl.alt)\t\(fl.description)
			"""
		}]
	}
}

#Flag: {
	name:        string
	alt:         string | *""
	description: string
	default?:    string
	arg?:        string
	example?:    string
}