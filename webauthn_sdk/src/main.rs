use anyhow::Result;


use generate::{DummyGenerator, DevGenerator};
use logger::LoggerGenerator;

extern crate termcolor;

mod compile;
mod parse;
mod generate;
mod run;
mod logger;

fn main() -> Result<()> {
    LoggerGenerator::new(DummyGenerator::new("cairo", "dev_sdk")).generate()?.compile()?.parse()?.run()
}
