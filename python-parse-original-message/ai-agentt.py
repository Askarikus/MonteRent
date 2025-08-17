from typing import Sequence
import sys
import uuid

from dotenv import find_dotenv, load_dotenv
from langchain_core.language_models import LanguageModelLike
from langchain_core.runnables import RunnableConfig
from langchain_core.tools import BaseTool, tool
from langchain_gigachat.chat_models import GigaChat
from langgraph.prebuilt import create_react_agent
from langgraph.checkpoint.memory import InMemorySaver


load_dotenv(find_dotenv())


try:
    REQUISITES_FILE = sys.argv[1]
except IndexError:
    exit("Передай аргументом файл с реквизитами")



class LLMAgent:
    def __init__(self, model: LanguageModelLike, tools: Sequence[BaseTool]):
        self._model = model
        self._agent = create_react_agent(
            model,
            tools=tools,
            checkpointer=InMemorySaver())
        self._config: RunnableConfig = {
                "configurable": {"thread_id": uuid.uuid4().hex}}

    def upload_file(self, file):
        print(f"upload file {file} to LLM")
        file_uploaded_id = self._model.upload_file(file).id_  # type: ignore
        return file_uploaded_id

    def invoke(
        self,
        content: str,
        attachments: list[str]|None=None,
        temperature: float=0.1
    ) -> str:
        """Отправляет сообщение в чат"""
        message: dict = {
            "role": "user",
            "content": content,
            **({"attachments": attachments} if attachments else {})
        }
        return self._agent.invoke(
            {
                "messages": [message],
                "temperature": temperature
            },
            config=self._config)["messages"][-1].content

def print_agent_response(llm_response: str) -> None:
    print(f"\033[35m{llm_response}\033[0m")


def main():
    model = GigaChat(
        model="GigaChat-2", # GigaChat-2-Pro, GigaChat-2-Max
        verify_ssl_certs=False,
    )

    agent = LLMAgent(model, tools=[])
    system_prompt = (
        "Твоя задача распаристь объявление о продаже или аренде жилья(квартиры, дома, участка).\
            и выдать на выходе цену"
    )

    file_uploaded_id= agent.upload_file(open(REQUISITES_FILE, "rb"))
    agent_response = agent.invoke(content=system_prompt, attachments=[file_uploaded_id])

    while(True):
        print_agent_response(agent_response)
        agent_response = agent.invoke()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nдосвидули!")
